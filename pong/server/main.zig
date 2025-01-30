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
const process = std.process;
const heap = std.heap;
const mem = std.mem;
const net = std.net;
const log = std.log;
const posix = std.posix;

const rg = @import("raygui");
const rl = @import("raylib");

const lib = @import("libpong");
const Request = lib.Request;
const Response = lib.Response;

const Ball = @import("Ball.zig");
const Board = @import("Board.zig");
const Client = @import("Client.zig");
const Paddle = @import("Paddle.zig");
const Player = @import("Player.zig");
const Pong = @import("Pong.zig");
const Server = @import("Server.zig");
const Config = @import("Config.zig");

pub fn main() !void {
    var gpa: heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();

    var config: Config = try .init(gpa.allocator());
    defer config.deinit();

    try config.parse();
}
