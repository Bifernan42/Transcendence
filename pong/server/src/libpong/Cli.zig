// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Cli.zig                                            :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/27 12:58:11 by pollivie          #+#    #+#             //
//   Updated: 2025/01/27 12:58:12 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const heap = std.heap;
const process = std.process;
const lib = @import("root.zig");
const Cli = @This();

pub const CliFlags = struct {
    ip: []const u8 = "127.0.0.1",
    port: u16 = 8080,
    tickrate: u16 = 60,
    board: lib.Board = .default,
    kind: lib.PongKind = .default,
    paddle: lib.Paddle = .default_dim,
    padd_speed: u16 = 1,
    ball_speed: u16 = 1,
    max_score: u8 = 1,

    pub const default: CliFlags = .{
        .ip = "127.0.0.1",
        .port = 8080,
        .tickrate = 60,
        .board = lib.Board.default,
        .kind = .local_ai,
        .paddle = lib.Paddle.default_dim,
        .padd_speed = 1,
        .ball_speed = 1,
        .max_score = 1,
    };

    pub fn format(
        self: @This(),
        comptime fmts: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmts;
        _ = options;
        try std.json.stringify(self, .{ .whitespace = .indent_4 }, writer);
    }
};

pub fn parseCliFlags(args: *process.ArgIterator) CliFlags {
    var flags: CliFlags = .default;

    if (!args.skip()) {
        return flags;
    }

    while (args.next()) |arg| {
        var arg_iter = std.mem.tokenizeScalar(u8, arg, '=');

        const flag_name = arg_iter.next() orelse continue;
        const flag_value = arg_iter.next() orelse continue;

        if (mem.eql(u8, "ip", flag_name)) {
            flags.ip = flag_value;
        } else if (mem.eql(u8, "port", flag_name)) {
            flags.port = fmt.parseInt(u16, flag_value, 10) catch CliFlags.default.port;
        } else if (mem.eql(u8, "board_width", flag_name)) {
            flags.board.dimension.width = fmt.parseInt(u16, flag_value, 10) catch CliFlags.default.board.dimension.width;
        } else if (mem.eql(u8, "board_height", flag_name)) {
            flags.board.dimension.height = fmt.parseInt(u16, flag_value, 10) catch CliFlags.default.board.dimension.height;
        } else if (mem.eql(u8, "paddle_width", flag_name)) {
            flags.paddle.hitbox.width = fmt.parseInt(u16, flag_value, 10) catch CliFlags.default.paddle.hitbox.width;
        } else if (mem.eql(u8, "paddle_height", flag_name)) {
            flags.paddle.hitbox.height = fmt.parseInt(u16, flag_value, 10) catch CliFlags.default.paddle.hitbox.height;
        } else if (mem.eql(u8, "tickrate", flag_name)) {
            flags.tickrate = fmt.parseInt(u16, flag_value, 10) catch CliFlags.default.tickrate;
        } else if (mem.eql(u8, "padd_speed", flag_name)) {
            flags.padd_speed = fmt.parseInt(u16, flag_value, 10) catch CliFlags.default.padd_speed;
        } else if (mem.eql(u8, "ball_speed", flag_name)) {
            flags.ball_speed = fmt.parseInt(u16, flag_value, 10) catch CliFlags.default.ball_speed;
        } else if (mem.eql(u8, "max_score", flag_name)) {
            flags.max_score = fmt.parseInt(u8, flag_value, 10) catch CliFlags.default.max_score;
        } else if (mem.eql(u8, "kind", flag_name)) {
            if (mem.eql(u8, "local_ai", flag_value)) {
                flags.kind = .local_ai;
            } else if (mem.eql(u8, "local_mp", flag_value)) {
                flags.kind = .local_mp;
            } else if (mem.eql(u8, "remote_mp", flag_value)) {
                flags.kind = .remote_mp;
            } else {
                flags.kind = CliFlags.default.kind;
            }
        }
    }
    return flags;
}

pub fn initState(state: *lib.protocol.Message, params: CliFlags) void {
    state.curr_state.board = params.board;
    state.curr_state.kind = params.kind;
    state.curr_state.player1.paddle.hitbox = params.paddle.hitbox;
}
