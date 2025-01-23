// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Cli.zig                                            :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/22 20:51:03 by pollivie          #+#    #+#             //
//   Updated: 2025/01/22 20:51:04 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const io = std.io;
const log = std.log;
const fmt = std.fmt;
const mem = std.mem;
const json = std.json;
const heap = std.heap;
const process = std.process;
const builtin = @import("builtin");
const Config = @import("Config.zig");
const Pong = @import("Pong.zig");

const Cli = @This();

arena: heap.ArenaAllocator = undefined,
argv: process.ArgIterator = undefined,

pub const default: Cli = .{
    .arena = undefined,
    .argv = undefined,
};

pub fn init(gpa: mem.Allocator) !Cli {
    var self: Cli = .default;
    self.arena = .init(gpa);
    self.argv = try process.argsWithAllocator(self.arena.allocator());
    return self;
}

pub fn deinit(self: *Cli) void {
    self.arena.deinit();
}

pub fn parseOrDefault(self: *Cli) !Config {
    var argv = self.argv;

    if (!argv.skip()) {
        return Config.default;
    }

    var config: Config = .default;
    while (argv.next()) |arg| {
        var arg_iterator = std.mem.tokenizeScalar(u8, arg, '=');

        const flag = arg_iterator.next() orelse continue;
        const maybe_value = arg_iterator.next();

        if (compareFlags("ip", flag)) {
            config.ip = maybe_value orelse Config.default.ip;
        } else if (compareFlags("port", flag)) {
            config.port = parseNumberOrFallback(u16, maybe_value, Config.default.port);
        } else if (compareFlags("tickrate", flag)) {
            config.tickrate = parseNumberOrFallback(u16, maybe_value, Config.default.tickrate);
        } else if (compareFlags("log_lvl", flag)) {
            config.log_lvl = parseNumberOrFallback(u2, maybe_value, Config.default.log_lvl);
        } else if (compareFlags("game_kind", flag)) {
            config.game_kind = Pong.GameKind.fromString(maybe_value orelse "local_ai") orelse Config.default.game_kind;
        } else if (compareFlags("player1_name", flag)) {
            config.player1_name = maybe_value orelse Config.default.player1_name;
        } else if (compareFlags("player2_name", flag)) {
            config.player2_name = maybe_value orelse Config.default.player2_name;
        } else if (compareFlags("paddle_speed", flag)) {
            config.paddle_speed = parseNumberOrFallback(u16, maybe_value, Config.default.paddle_speed);
        } else if (compareFlags("ball_speed", flag)) {
            config.ball_speed = parseNumberOrFallback(u16, maybe_value, Config.default.ball_speed);
        } else if (compareFlags("vt_board_width", flag)) {
            config.vt_board_width = parseNumberOrFallback(u16, maybe_value, Config.default.vt_board_width);
        } else if (compareFlags("vt_board_height", flag)) {
            config.vt_board_height = parseNumberOrFallback(u16, maybe_value, Config.default.vt_board_height);
        } else if (compareFlags("vt_ball_radius", flag)) {
            config.vt_ball_radius = parseNumberOrFallback(u16, maybe_value, Config.default.vt_ball_radius);
        } else if (compareFlags("vt_paddle_width", flag)) {
            config.vt_paddle_width = parseNumberOrFallback(u16, maybe_value, Config.default.vt_paddle_width);
        } else if (compareFlags("vt_paddle_height", flag)) {
            config.vt_paddle_height = parseNumberOrFallback(u16, maybe_value, Config.default.vt_paddle_height);
        } else if (compareFlags("ai_difficulty", flag)) {
            config.ai_difficulty = Pong.Difficulty.fromString(maybe_value orelse "normal") orelse Config.default.ai_difficulty;
        }
    }
    return config;
}

fn parseNumberOrFallback(comptime T: type, maybe_num: ?[]const u8, fallback: T) T {
    const num = maybe_num orelse return fallback;
    return fmt.parseInt(T, num, 10) catch fallback;
}

fn compareFlags(s1: []const u8, s2: []const u8) bool {
    return mem.eql(u8, s1, s2);
}
