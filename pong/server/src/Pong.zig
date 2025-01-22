// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Pong.zig                                           :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/22 15:40:41 by pollivie          #+#    #+#             //
//   Updated: 2025/01/22 15:40:41 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const builtin = @import("builtin");
const std = @import("std");
const json = std.json;
const Pong = @This();

const opts: json.StringifyOptions = switch (builtin.mode) {
    .Debug => .{ .whitespace = .indent_4 },
    else => .{},
};

pub const GameKind = enum {
    local_ai,
    local_mp,
    remote_mp,

    pub const default: GameKind = .local_ai;
};

pub const Vector2 = struct {
    x: i32 = 0,
    y: i32 = 0,

    pub const default: Vector2 = .{
        .x = 0,
        .y = 0,
    };

    pub fn init(value: Vector2) Vector2 {
        return .{
            .x = value.x,
            .y = value.y,
        };
    }

    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try json.stringify(self, opts, writer);
    }
};

pub const Paddle = struct {
    position: Vector2 = .default,
    velocity: Vector2 = .default,
    width: u32 = 0,
    height: u32 = 0,

    pub const default: Paddle = .{
        .position = Vector2.default,
        .velocity = Vector2.default,
        .width = 0,
        .height = 0,
    };

    pub fn init(position: Vector2, velocity: Vector2, width: u32, height: u32) Paddle {
        return .{
            .position = position,
            .velocity = velocity,
            .width = width,
            .height = height,
        };
    }

    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try json.stringify(self, opts, writer);
    }
};

pub const Player = struct {
    name: []const u8 = "none",
    score: u32 = 0,
    paddle: Paddle = .default,

    pub const default: Player = .{
        .name = "none",
        .score = 0,
        .paddle = Paddle.default,
    };

    pub const p1: Player = .{
        .name = "P1",
        .score = 0,
        .paddle = Paddle.default,
    };

    pub const p2: Player = .{
        .name = "P2",
        .score = 0,
        .paddle = Paddle.default,
    };

    pub const ai: Player = .{
        .name = "AI",
        .score = 0,
        .paddle = Paddle.default,
    };

    pub const Action = enum {
        press_none,
        press_up,
        press_down,
        press_pause,
        press_resume,

        pub const default: Action = .press_none;
    };

    pub const Event = struct {
        event: Player.Action = .press_none,
        timestamp: i64 = 0,

        pub const default: Player.Event = .{
            .event = .press_none,
            .timestamp = 0,
        };

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            try json.stringify(self, opts, writer);
        }
    };

    pub fn init(name: []const u8, score: u32, paddle: Paddle) Player {
        return .{
            .name = name,
            .score = score,
            .paddle = paddle,
        };
    }

    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try json.stringify(self, opts, writer);
    }
};

pub const Board = struct {
    position: Vector2 = .default,
    width: u32 = 0,
    height: u32 = 0,

    pub const default: Board = .{
        .position = Vector2.default,
        .width = 0,
        .height = 0,
    };

    pub fn init(position: Vector2, width: u32, height: u32) Board {
        return .{
            .position = position,
            .width = width,
            .height = height,
        };
    }

    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try json.stringify(self, opts, writer);
    }
};

pub const Ball = struct {
    position: Vector2 = .default,
    velocity: Vector2 = .default,
    radius: f32 = 0.0,
    speed: f32 = 0.0,

    pub const default: Ball = .{
        .position = Vector2.default,
        .velocity = Vector2.default,
        .radius = 0.0,
        .speed = 0.0,
    };

    pub fn init(position: Vector2, velocity: Vector2, radius: f32, speed: f32) Ball {
        return .{
            .position = position,
            .velocity = velocity,
            .radius = radius,
            .speed = speed,
        };
    }
    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try json.stringify(self, opts, writer);
    }
};

pub const GameState = struct {
    kind: GameKind = .default,
    board: Board = .default,
    ball: Ball = .default,
    player1: Player = .default,
    player2: Player = .default,
    player1_events: []Player.Event = &[_]Player.Event{},
    player2_events: []Player.Event = &[_]Player.Event{},
    timestamp: i64 = 0,

    pub const default: GameState = .{
        .kind = .local_ai,
        .board = Board.default,
        .ball = Ball.default,
        .player1 = Player.p1,
        .player2 = Player.ai,
        .player1_events = &[_]Player.Event{},
        .player2_events = &[_]Player.Event{},
        .timestamp = 0,
    };

    pub fn init(kind: GameKind, board: Board, ball: Ball, player1: Player, player2: Player) GameState {
        return .{
            .kind = kind,
            .board = board,
            .ball = ball,
            .player1 = player1,
            .player2 = player2,
            .player1_events = &[_]Player.Event{},
            .player2_events = &[_]Player.Event{},
            .timestamp = 0,
        };
    }

    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try json.stringify(self, opts, writer);
    }
};
