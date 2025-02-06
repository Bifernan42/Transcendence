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
    log.info("[{d}] initializing memory allocator", .{std.time.timestamp()});

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
    // const db_username = envp.get("POSTGRES_USER") orelse "admin";
    // const db_password = envp.get("POSTGRES_PASSWORD") orelse "admin_password";
    // const db_host = envp.get("DB_HOST") orelse "0.0.0.0";
    // const db_port = std.fmt.parseInt(u16, envp.get("DB_PORT") orelse "5432", 10) catch 5432;

    // log.info("[{d}] db_username = {s}, db_password = {s}, db_host = {s}, db_port = {d}", .{ std.time.timestamp(), db_username, db_password, db_host, db_port });
    // const db_pool_options: pg.Pool.Opts = .{
    //     .auth = .{
    //         .database = "postgres",
    //         .username = "admin",
    //         .password = "admin_password",
    //     },
    //     .connect = .{
    //         .host = "0.0.0.0",
    //         .port = 5432,
    //     },
    // };
    // log.info("[{d}] initializing envp map", .{std.time.timestamp()});

    // log.info("[{d}] opening db_pool connections", .{std.time.timestamp()});
    // var db_pool = pg.Pool.init(allocator, db_pool_options) catch |err| {
    //     log.err("fatal error {!}. shutting down.", .{err});
    //     return FAILURE;
    // };
    // defer db_pool.deinit();

    const db_pool = pg.Pool.initUri(allocator, uri, 2, 10_000) catch |err| {
        log.err("fatal error {!}. shutting down.", .{err});
        return FAILURE;
    };

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

    log.info("[{d}] listening on : 0.0.0.0:8081", .{std.time.timestamp()});
    std.debug.print("listening", .{});
    server.listen() catch |err| {
        log.err("fatal error {!}. shutting down.", .{err});
        return FAILURE;
    };

    var router = server.router(.{});
    router.get("/", index, .{ .handler = &runtime });
    router.get("/play/:game_id", Runtime.handleWebSocketUpgrade, .{ .handler = &runtime });

    log.info("[{d}] exiting server", .{std.time.timestamp()});
    return SUCCESS;
}

pub fn index(rt: *Runtime, req: *httpz.Request, res: *httpz.Response) !void {
    _ = rt;
    _ = req;
    res.body =
        \\     <!DOCTYPE html>
        \\ <html lang="en">
        \\ <head>
        \\   <meta charset="UTF-8">
        \\   <title>Pong</title>
        \\ </head>
        \\ <body>
        \\   <h1>Pong</h1>
        \\   <a href="/play/1">Play Pong</a>
        \\ </body>
        \\ </html>
    ;
    res.status = 200;
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
