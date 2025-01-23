// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Config.zig                                         :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/22 20:53:04 by pollivie          #+#    #+#             //
//   Updated: 2025/01/22 20:53:05 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const io = std.io;
const log = std.log;
const mem = std.mem;
const json = std.json;
const heap = std.heap;
const process = std.process;
const builtin = @import("builtin");

const Pong = @import("Pong.zig");

const Config = @This();

ip: []const u8 = "127.0.0.1",
port: u16 = 8080,
tickrate: u16 = if (builtin.mode == .Debug) 5 else 256,
log_lvl: u2 = 3,
game_kind: Pong.GameKind = .local_ai,
player1_name: []const u8 = "P1",
player2_name: []const u8 = "AI",
paddle_speed: u16 = 8,
ball_speed: u16 = 256,
vt_board_width: u16 = 1024,
vt_board_height: u16 = 512,
vt_ball_radius: u16 = 4,
vt_paddle_width: u16 = 8,
vt_paddle_height: u16 = 64,
ai_difficulty: Pong.Difficulty = .normal,

pub const default: Config = .{
    .ip = "127.0.0.1",
    .port = 8080,
    .tickrate = if (builtin.mode == .Debug) 5 else 256,
    .log_lvl = 3,
    .game_kind = .local_ai,
    .player1_name = "P1",
    .player2_name = "AI",
    .paddle_speed = 8,
    .ball_speed = 256,
    .vt_board_width = 1024,
    .vt_board_height = 512,
    .vt_ball_radius = 4,
    .vt_paddle_width = 8,
    .vt_paddle_height = 64,
    .ai_difficulty = .normal,
};

pub fn format(
    self: @This(),
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    _ = options;
    _ = fmt;
    try json.stringify(self, opts, writer);
}

const opts: json.StringifyOptions = switch (builtin.mode) {
    .Debug => .{ .whitespace = .indent_4 },
    else => .{},
};
