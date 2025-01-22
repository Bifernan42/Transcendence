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

const Pong = @import("Pong.zig");
const Protocol = @import("Protocol.zig");

pub fn main() !void {
    var gpa: heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();

    const stdout_handle = io.getStdOut();
    const stdout = stdout_handle.writer();

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
