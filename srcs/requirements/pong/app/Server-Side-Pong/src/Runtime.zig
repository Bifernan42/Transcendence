// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Runtime.zig                                        :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/02/04 10:31:35 by pollivie          #+#    #+#             //
//   Updated: 2025/02/04 10:31:35 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const log = std.log;
const mem = std.mem;
const heap = std.heap;
const httpz = @import("httpz");
const ws = httpz.websocket;
const pg = @import("pg");
const GamePool = @import("GamePool.zig");
const Client = @import("Client.zig");
const Runtime = @This();

pub const std_options: std.Options = .{
    .log_level = .debug,
};

allocator: mem.Allocator,
db_pool: *pg.Pool,
gm_pool: *GamePool,

pub fn handleWebSocketUpgradeFetchGame(rt: *Runtime, req: *httpz.Request, res: *httpz.Response) !void {
    // Extract game_id from URL parameters
    const game_id = req.param("game_id") orelse {
        log.err("Missing game_id parameter in request", .{});
        res.status = 400;
        res.body = "WebSocket handshake failed: missing game_id parameter.";
        return;
    };

    log.debug("Received WebSocket upgrade request for game_id: {s}", .{game_id});

    // Prepare the query to fetch game configuration from DB
    const QUERY =
        \\ SELECT game_kind, max_score, board_width, board_height,
        \\ paddle_width, paddle_height, paddle_speed,
        \\ ball_radius, ball_speed
        \\ FROM game_object
        \\ WHERE game_id = $1
    ;

    // Query the database for the game configuration
    var result = rt.db_pool.query(QUERY, .{game_id}) catch |err| {
        log.err("Database query failed for game_id '{s}': {s} | error: {any}", .{ game_id, QUERY, err });
        res.status = 500;
        res.body = "Internal Server Error: failed to fetch game configuration.";
        return;
    };
    defer result.deinit();

    var maybe_game_options: ?GamePool.Game.Options = null;
    if (try result.next()) |row| {
        // Construct game options from DB row
        maybe_game_options = .{
            .vt_game_kind = switch (row.get(i32, 0)) {
                0 => .local_ai,
                1 => .local_mp,
                2 => .remote_mp,
                else => {
                    log.err("Invalid game kind '{d}' for game_id '{s}'", .{ row.get(i32, 0), game_id });
                    res.status = 400;
                    res.body = "WebSocket handshake failed: invalid game kind.";
                    return;
                },
            },
            .vt_game_max_score = row.get(u8, 1),
            .vt_game_board_width = row.get(u16, 2),
            .vt_game_board_height = row.get(u16, 3),
            .vt_game_paddle_width = row.get(u16, 4),
            .vt_game_paddle_height = row.get(u16, 5),
            .vt_game_paddle_speed = row.get(u16, 6),
            .vt_game_ball_radius = row.get(u16, 7),
            .vt_game_ball_speed = row.get(u16, 8),
        };
        log.info("Game configuration fetched successfully for game_id '{s}'", .{game_id});
    } else {
        log.err("No game configuration found in DB for game_id '{s}'", .{game_id});
        res.status = 404;
        res.body = "Game not found.";
        return;
    }

    const game_options = maybe_game_options orelse {
        log.err("Failed to obtain game options for game_id '{s}'", .{game_id});
        res.status = 500;
        res.body = "Internal Server Error: game configuration missing.";
        return;
    };

    // Retrieve or create the game from the GamePool
    var game = rt.gm_pool.getGame(game_id) orelse blk: {
        log.info("Creating new game for game_id '{s}'", .{game_id});
        break :blk rt.gm_pool.createGame(game_id, game_options) catch |err| {
            log.err("Error creating game for game_id '{s}': {any}", .{ game_id, err });
            res.status = 500;
            res.body = "Internal Server Error: could not create game.";
            return;
        };
    };

    // Create a new WebSocket client instance
    const client = Client.init("1", game);
    log.debug("Client initialized for game_id '{s}'", .{game_id});

    // Attempt to join the game with the new client
    game.join(client) catch |err| switch (err) {
        error.GameIsFull, error.GameIsDone, error.InvalidAction => {
            log.err("Client failed to join game '{s}': {any}", .{ game_id, err });
            res.status = 400;
            res.body = "WebSocket handshake failed: game cannot accept new client.";
            return;
        },
    };

    // Set up WebSocket context
    const ctx: WebsocketContext = .{
        .player = client,
        .conn = undefined,
    };

    // Upgrade HTTP connection to WebSocket
    const upgrade = httpz.upgradeWebsocket(WebsocketHandler, req, res, ctx) catch |err| {
        log.err("WebSocket upgrade error for game_id '{s}': {any}", .{ game_id, err });
        res.status = 400;
        res.body = "WebSocket handshake failed during upgrade.";
        return;
    };
    log.info("WebSocket upgrade successful for game_id '{s}'", .{game_id});
    _ = upgrade;
}

pub fn notFound(_: *Runtime, req: *httpz.Request, res: *httpz.Response) !void {
    const str = try std.json.stringifyAlloc(req.arena, req.url, .{ .whitespace = .indent_4 });
    log.debug("Request not found: {s}", .{str});
    res.status = 404;
    res.body = str;
}

pub fn uncaughtError(_: *Runtime, req: *httpz.Request, res: *httpz.Response, err: anyerror) void {
    log.err("Uncaught error processing {any} {s}: {any}", .{ req.method, req.url.path, err });
    res.status = 500;
    res.body = "Internal Server Error: an unexpected error occurred.";
}

pub const WebsocketContext = struct {
    player: Client,
    conn: *ws.Conn,
};

pub const WebsocketHandler = struct {
    connection: *ws.Conn,
    context: WebsocketContext,

    pub fn init(conn: *ws.Conn, ctx: WebsocketContext) !WebsocketHandler {
        log.debug("Initializing WebSocket handler", .{});
        return .{
            .connection = conn,
            .context = .{
                .player = ctx.player,
                .conn = conn,
            },
        };
    }

    pub fn clientMessage(self: *WebsocketHandler, data: []const u8) !void {
        log.info("Received message from client {any}: {s}", .{ self, data });
    }

    pub fn close(self: *WebsocketHandler) void {
        log.info("Closing WebSocket for client", .{});
        self.context.player.game.quit(self.context.player) catch |err| {
            log.err("Error while closing client: {any}", .{err});
        };
    }
};

// Initializes the runtime (handler for httpz.Server)
pub fn init(allocator: mem.Allocator, db_pool: ?*pg.Pool, gm_pool: *GamePool) !Runtime {
    log.info("Initializing runtime", .{});
    return .{
        .allocator = allocator,
        .db_pool = db_pool orelse undefined,
        .gm_pool = gm_pool,
    };
}

pub fn deinit(self: *Runtime) void {
    log.info("Deinitializing runtime", .{});
    _ = self;
}

// WebSocket upgrade route
pub fn handleWebSocketUpgrade(rt: *Runtime, req: *httpz.Request, res: *httpz.Response) !void {
    const game_id = req.param("game_id") orelse {
        log.err("Missing game_id in WebSocket upgrade request", .{});
        res.status = 400;
        res.body = "WebSocket handshake failed: missing game_id.";
        return;
    };

    log.debug("Processing WebSocket upgrade for game_id '{s}'", .{game_id});

    const default_options = GamePool.Game.Options{
        .vt_game_kind = .local_ai,
        .vt_game_max_score = 10,
        .vt_game_board_width = 800,
        .vt_game_board_height = 600,
        .vt_game_paddle_width = 20,
        .vt_game_paddle_height = 100,
        .vt_game_paddle_speed = 5,
        .vt_game_ball_radius = 10,
        .vt_game_ball_speed = 4,
    };

    // Retrieve or create a game
    var game = rt.gm_pool.getGame(game_id) orelse blk: {
        log.info("Creating new game for game_id '{s}'", .{game_id});
        break :blk rt.gm_pool.createGame(game_id, default_options) catch |err| {
            log.err("Error creating game for game_id '{s}': {!}", .{ game_id, err });
            res.status = 500;
            res.body = "Internal Server Error: could not create game.";
            return;
        };
    };

    res.content_type = .JSON;
    res.body = try std.fmt.allocPrint(res.arena, "{}", .{game.states});
    log.info("Game state returned for game_id '{s}'", .{game_id});

    const client = Client.init("1", game);
    log.debug("Client initialized for WebSocket upgrade in game_id '{s}'", .{game_id});
    game.join(client) catch |err| switch (err) {
        error.GameIsFull, error.GameIsDone, error.InvalidAction => {
            log.err("Client failed to join game '{s}' during upgrade: {!}", .{ game_id, err });
            res.status = 400;
            res.body = "WebSocket handshake failed: game cannot accept new client.";
            return;
        },
    };

    const ctx: WebsocketContext = .{
        .player = client,
        .conn = undefined,
    };

    const upgrade = httpz.upgradeWebsocket(WebsocketHandler, req, res, ctx) catch |err| {
        log.err("WebSocket upgrade error for game_id '{s}': {any}", .{ game_id, err });
        res.status = 400;
        res.body = "WebSocket handshake failed during upgrade.";
        return;
    };
    log.info("WebSocket upgrade completed for game_id '{s}'", .{game_id});
    _ = upgrade;
}
