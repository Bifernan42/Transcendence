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

server_ip: ?[]const u8 = null,
server_port: ?u16 = null,
server_tickrate: ?u16 = null,
server_log_lvl: ?u2 = null,

pong_game_kind: ?Pong.GameKind = null,
pong_player1_name: ?[]const u8 = null,
pong_player2_name: ?[]const u8 = null,
pong_paddle_speed: ?i32 = null,
pong_ball_speed: ?i32 = null,

pong_vt_board_width: ?i32 = null,
pong_vt_board_height: ?i32 = null,
pong_vt_ball_radius: ?f32 = null,
pong_vt_paddle_width: ?i32 = null,
pong_vt_paddle_height: ?i32 = null,

pong_ai_difficulty: ?Pong.Difficulty,

pub const default: Config = .{
    .server_ip = null,
    .server_port = null,
    .server_tickrate = null,
    .server_log_lvl = null,
    .pong_game_kind = null,
    .pong_player1_name = null,
    .pong_player2_name = null,
    .pong_paddle_speed = null,
    .pong_ball_speed = null,
    .pong_vt_board_width = null,
    .pong_vt_board_height = null,
    .pong_vt_ball_radius = null,
    .pong_vt_paddle_width = null,
    .pong_vt_paddle_height = null,
    .pong_ai_difficulty = null,
};

pub const fallback: Config = .{
    .server_ip = "127.0.0.1",
    .server_port = 8080,
    .server_tickrate = 256,
    .server_log_lvl = 3,
    .pong_game_kind = .local_ai,
    .pong_player1_name = "P1",
    .pong_player2_name = "Ai",
    .pong_paddle_speed = 10,
    .pong_ball_speed = 300,
    .pong_vt_board_width = 1024,
    .pong_vt_board_height = 372,
    .pong_vt_ball_radius = 8,
    .pong_vt_paddle_width = 8,
    .pong_vt_paddle_height = 64,
    .pong_ai_difficulty = .normal,
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
