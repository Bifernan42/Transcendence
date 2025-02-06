// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   main.zig                                           :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/30 10:09:28 by pollivie          #+#    #+#             //
//   Updated: 2025/01/30 10:09:29 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const log = std.log;
const heap = std.heap;
const process = std.process;
const httpz = @import("httpz");
const pg = @import("pg");
const Client = @import("Client.zig");
const Runtime = @import("Runtime.zig");
const GamePool = @import("GamePool.zig");

pub const std_options: std.Options = .{
    .log_level = .debug,
};

const SUCCESS: u8 = 0;
const FAILURE: u8 = 1;

pub fn main() !u8 {
    log.info("[{d}] starting pong server process", .{std.time.timestamp()});
    const gpa_options: heap.GeneralPurposeAllocatorConfig = .{
        .safety = true,
        .thread_safe = true,
        .never_unmap = true,
        .retain_metadata = true,
    };

    var gpa: heap.GeneralPurposeAllocator(gpa_options) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var envp = process.getEnvMap(allocator) catch |err| {
        log.err("fatal error {!}. shutting down.", .{err});
        return FAILURE;
    };
    defer envp.deinit();
    log.info("[{d}] initializing envp map", .{std.time.timestamp()});

    const db_url = envp.get("DATABASE_URL") orelse "";
    log.info("[{d}] trying to open connection from db_url {s}", .{ std.time.timestamp(), db_url });
    const uri = std.Uri.parse(db_url) catch |err| {
        log.err("fatal error {!}. shutting down.", .{err});
        return FAILURE;
    };

    const db_pool = pg.Pool.initUri(allocator, uri, 2, 10_000) catch |err| {
        pg.printSSLError();
        log.err("fatal error {!}. shutting down.", .{err});
        return FAILURE;
    };
    defer db_pool.deinit();

    var game_pool = GamePool.init(allocator, db_pool);
    defer game_pool.deinit();

    log.info("[{d}] initializing runtime of pong server", .{std.time.timestamp()});
    var runtime = Runtime.init(allocator, db_pool, &game_pool) catch |err| {
        log.err("fatal error {!}. shutting down.", .{err});
        return FAILURE;
    };
    defer runtime.deinit();

    const server_options: httpz.Config = .{
        .port = 8081,
        .address = "0.0.0.0",
        .thread_pool = .{
            .count = 8,
        },
    };

    log.info("[{d}] initializing http server on : 0.0.0.0:8081", .{std.time.timestamp()});
    var server = httpz.Server(*Runtime).init(allocator, server_options, &runtime) catch |err| {
        log.err("fatal error {!}. shutting down.", .{err});
        return FAILURE;
    };
    defer {
        server.stop();
        server.deinit();
    }

    var router = server.router(.{});
    router.tryGet("/", index, .{ .handler = &runtime }) catch |err| {
        log.err("fatal error {!}. shutting down.", .{err});
        return FAILURE;
    };

    router.tryGet("/play/nodb/:game_id", Runtime.handleWebSocketUpgrade, .{ .handler = &runtime }) catch |err| {
        log.err("fatal error {!}. shutting down.", .{err});
        return FAILURE;
    };

    router.tryGet("/play/db/:game_id", Runtime.handleWebSocketUpgradeFetchGame, .{ .handler = &runtime }) catch |err| {
        log.err("fatal error {!}. shutting down.", .{err});
        return FAILURE;
    };

    log.info("[{d}] listening : 0.0.0.0:8081", .{std.time.timestamp()});
    server.listen() catch |err| {
        log.err("fatal error {!}. shutting down.", .{err});
        return FAILURE;
    };

    log.info("[{d}] exiting server", .{std.time.timestamp()});
    return SUCCESS;
}

pub fn index(_: *Runtime, req: *httpz.Request, res: *httpz.Response) !void {
    log.info("[{d}] redirected to {any}", .{ std.time.timestamp(), req.url });
    res.body =
        \\<!DOCTYPE html>
        \\<html lang="en">
        \\<head>
        \\<meta charset="UTF-8">
        \\<title>Pong</title>
        \\</head>
        \\<body>
        \\<h1>Pong</h1>
        \\<a href="/play/nodb/1">Pong websocket endpoint</a>
        \\<a href="/play/db/1">Pong websocket db check endpoint</a>
        \\</body>
        \\</html>
    ;
}

test "request" {
    const allocator = std.heap.page_allocator;

    // Initialize runtime (handler)
    var game_pool = GamePool.init(allocator, null);
    defer game_pool.deinit();

    var runtime = Runtime.init(allocator, null, &game_pool) catch |err| {
        std.debug.print("Fatal error {!}. Shutting down.\n", .{err});
        return;
    };
    defer runtime.deinit();

    var web_test = httpz.testing.init(.{});
    defer web_test.deinit();

    // Simulate request to /play/game123
    web_test.param("game_id", "game123");
    web_test.query("player_id", "p1");

    // Call handler
    try Runtime.handleWebSocketUpgrade(&runtime, web_test.req, web_test.res);

    // Print response
    std.debug.print("Response status: {}\n", .{web_test.res.status});
    std.debug.print("Response body: {s}\n", .{web_test.res.body});
}
