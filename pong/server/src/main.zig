// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   main.zig                                           :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/19 15:12:20 by pollivie          #+#    #+#             //
//   Updated: 2025/01/19 15:12:21 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const io = std.io;
const net = std.net;
const mem = std.mem;
const log = std.log;
const heap = std.heap;
const posix = std.posix;
const process = std.process;
const json = std.json;

const Cli = @import("Cli.zig");
const Config = @import("Config.zig");
const Pong = @import("Pong.zig");
const Protocol = @import("Protocol.zig");
const Server = @import("Server.zig");

const stdout_handle = io.getStdOut();
const stdout = stdout_handle.writer();

fn jsonDemo() !void {
    try stdout.print("Pong.Vector2.default {}\n", .{Pong.Vector2.default});
    try stdout.print("Pong.Paddle.default {}\n", .{Pong.Paddle.default});
    try stdout.print("Pong.Player.default {}\n", .{Pong.Player.default});
    try stdout.print("Pong.Board.default {}\n", .{Pong.Board.default});
    try stdout.print("Pong.Ball.default {}\n", .{Pong.Ball.default});
    try stdout.print("Pong.GameState.default {}\n", .{Pong.GameState.default});
    try stdout.print("Protocol.Handshake.Request.default {}\n", .{Protocol.Handshake.Request.default});
    try stdout.print("Protocol.Handshake.Response.default {}\n", .{Protocol.Handshake.Response.default});
    try stdout.print("Protocol.Config.Request.default {}\n", .{Protocol.Config.Request.default});
    try stdout.print("Protocol.Config.Response.default {}\n", .{Protocol.Config.Response.default});
    try stdout.print("Protocol.Update.Request.default {}\n", .{Protocol.Update.Request.default});
    try stdout.print("Protocol.Update.Response.default {}\n", .{Protocol.Update.Response.default});
}

pub fn main() !u8 {
    var gpa: heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();

    var parser: Cli = try .init(gpa.allocator());
    defer parser.deinit();

    const config: Config = try parser.parseOrDefault();
    log.info("{}", .{config});

    var server: Server = Server.init(gpa.allocator(), config) catch |err| {
        log.err("server initialization failed with {!}.", .{err});
        return 1;
    };
    defer server.deinit();

    server.run() catch |err| {
        log.err("server failed with {!}.", .{err});
        return 1;
    };

    return 0;
}
