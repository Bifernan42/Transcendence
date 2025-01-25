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

const std = @import("std");
const mem = std.mem;
const json = std.json;
const builtin = @import("builtin");
const Config = @import("Config.zig");

const Pong = @This();

pub const Formatting: json.StringifyOptions = if (builtin.mode == .Debug) .{ .whitespace = .indent_4 } else .{};

pub const Difficulty = enum {
    recruit,
    normal,
    commando,
    veteran,
    cheater,

    pub fn fromString(maybe_difficulty: []const u8) ?Difficulty {
        if (mem.eql(u8, "recruit", maybe_difficulty)) {
            return Difficulty.recruit;
        } else if (mem.eql(u8, "normal", maybe_difficulty)) {
            return Difficulty.normal;
        } else if (mem.eql(u8, "commando", maybe_difficulty)) {
            return Difficulty.commando;
        } else if (mem.eql(u8, "veteran", maybe_difficulty)) {
            return Difficulty.veteran;
        } else if (mem.eql(u8, "cheater", maybe_difficulty)) {
            return Difficulty.cheater;
        } else {
            return null;
        }
    }
};

pub const GameKind = enum {
    local_ai,
    local_mp,
    remote_mp,

    pub const default: GameKind = .local_ai;

    pub fn fromString(maybe_kind: []const u8) ?GameKind {
        if (mem.eql(u8, "local_ai", maybe_kind)) {
            return GameKind.local_ai;
        } else if (mem.eql(u8, "local_mp", maybe_kind)) {
            return GameKind.local_mp;
        } else if (mem.eql(u8, "remote_mp", maybe_kind)) {
            return GameKind.local_mp;
        } else {
            return null;
        }
    }
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
        try json.stringify(self, Formatting, writer);
    }
};

pub const Paddle = struct {
    position: Vector2 = .default,
    speed: f32 = 0,
    width: u32 = 0,
    height: u32 = 0,

    pub const default: Paddle = .{
        .position = Vector2.default,
        .speed = 0,
        .width = 0,
        .height = 0,
    };

    pub fn init(position: Vector2, speed: u16, width: u32, height: u32) Paddle {
        return .{
            .position = position,
            .speed = @floatFromInt(speed),
            .width = width,
            .height = height,
        };
    }

    pub fn initFromConfig(config: Config) Paddle {
        return init(
            Vector2.default,
            config.paddle_speed,
            config.vt_paddle_width,
            config.vt_paddle_height,
        );
    }

    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try json.stringify(self, Formatting, writer);
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

        pub fn fromString(maybe_action: []const u8) ?Action {
            if (mem.eql(u8, "press_none", maybe_action)) {
                return Action.press_none;
            } else if (mem.eql(u8, "press_up", maybe_action)) {
                return Action.press_up;
            } else if (mem.eql(u8, "press_down", maybe_action)) {
                return Action.press_down;
            } else if (mem.eql(u8, "press_pause", maybe_action)) {
                return Action.press_pause;
            } else if (mem.eql(u8, "press_resume", maybe_action)) {
                return Action.press_resume;
            }
        }
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
            try json.stringify(self, Formatting, writer);
        }
    };

    pub fn init(name: []const u8, score: u32, paddle: Paddle) Player {
        return .{
            .name = name,
            .score = score,
            .paddle = paddle,
        };
    }

    pub const Identity = enum {
        p1,
        p2,
        ai,
    };

    pub fn initFromConfig(config: Config, who: Identity) Player {
        return switch (who) {
            .p1 => init(config.player1_name, 0, Paddle.initFromConfig(config)),
            .p2 => init(config.player2_name, 0, Paddle.initFromConfig(config)),
            .ai => init("AI", 0, Paddle.initFromConfig(config)),
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
        try json.stringify(self, Formatting, writer);
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

    pub fn initFromConfig(config: Config) Board {
        return init(
            Vector2.default,
            config.vt_board_width,
            config.vt_board_height,
        );
    }

    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try json.stringify(self, Formatting, writer);
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

    pub fn init(position: Vector2, velocity: Vector2, radius: u16, speed: u16) Ball {
        return .{
            .position = position,
            .velocity = velocity,
            .radius = @floatFromInt(radius),
            .speed = @floatFromInt(speed),
        };
    }

    pub fn initFromConfig(config: Config) Ball {
        return init(
            Vector2.default,
            Vector2.default,
            config.vt_ball_radius,
            config.ball_speed,
        );
    }

    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try json.stringify(self, Formatting, writer);
    }
};

pub const GameState = struct {
    kind: GameKind = .default,
    board: Board = .default,
    ball: Ball = .default,
    player1: Player = .default,
    player2: Player = .default,
    player1_events: Player.Event = .default,
    player2_events: Player.Event = .default,
    timestamp: i64 = 0,

    pub const default: GameState = .{
        .kind = .local_ai,
        .board = Board.default,
        .ball = Ball.default,
        .player1 = Player.p1,
        .player2 = Player.ai,
        .player1_events = .default,
        .player2_events = .default,
        .timestamp = 0,
    };

    pub fn init(kind: GameKind, board: Board, ball: Ball, player1: Player, player2: Player) GameState {
        return .{
            .kind = kind,
            .board = board,
            .ball = ball,
            .player1 = player1,
            .player2 = player2,
            .player1_events = .default,
            .player2_events = .default,
            .timestamp = 0,
        };
    }

    pub fn initFromConfig(config: Config) GameState {
        const board = Board.initFromConfig(config);
        const ball = Ball.initFromConfig(config);
        return switch (config.game_kind) {
            .local_mp => gs: {
                const p1 = Player.initFromConfig(config, .p1);
                const p2 = Player.initFromConfig(config, .p2);
                break :gs init(.local_mp, board, ball, p1, p2);
            },
            .local_ai => gs: {
                const p1 = Player.initFromConfig(config, .p1);
                const ai = Player.initFromConfig(config, .ai);
                break :gs init(.local_ai, board, ball, p1, ai);
            },
            .remote_mp => gs: {
                const p1 = Player.initFromConfig(config, .p1);
                const p2 = Player.initFromConfig(config, .p2);
                break :gs init(.remote_mp, board, ball, p1, p2);
            },
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
        try json.stringify(self, Formatting, writer);
    }
};
