// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   protocol.zig                                       :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/27 10:53:57 by pollivie          #+#    #+#             //
//   Updated: 2025/01/27 10:53:57 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");

pub const PlayerMove = enum(u4) {
    none = 0,
    p1_up = 1,
    p1_down = 2,
    p1_noop = 3,
    p2_up = 4,
    p2_down = 5,
    p2_noop = 6,

    pub const zero: PlayerMove = .none;
    pub const default: PlayerMove = .p1_noop;

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

pub const PlayerRole = enum(u4) {
    none = 0,
    bot = 1,
    player1 = 2,
    player2 = 3,
    spectator = 4,

    pub const zero: PlayerRole = .none;
    pub const default: PlayerRole = .none;

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
pub const PlayerScore = enum(u4) {
    _0 = 0,
    _1 = 1,
    _2 = 2,
    _3 = 3,
    _4 = 4,
    _5 = 5,
    _6 = 6,
    _7 = 7,
    _8 = 8,

    pub const zero: PlayerScore = ._0;
    pub const default: PlayerScore = ._0;

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
pub const PlayerState = enum(u4) {
    none = 0,
    connected = 1,
    authentificated = 2,
    disconnected = 3,
    done = 4,
    playing = 5,
    reconnected = 6,
    waiting = 7,

    pub const zero: PlayerState = .none;
    pub const default: PlayerState = .disconnected;

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

pub const PongKind = enum(u4) {
    none = 0,
    local_ai = 1,
    local_mp = 2,
    remote_mp = 3,

    pub const zero: PongKind = .local_ai;
    pub const default: PongKind = .local_ai;

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
pub const Surface = enum(u8) {
    none = 0,
    paddle_1 = 1,
    paddle_2 = 2,
    wall_up = 3,
    wall_down = 4,
    wall_left = 5,
    wall_right = 6,

    pub const default: Surface = .none;
    pub const zero: Surface = .none;

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

pub const Vector2 = packed struct(u32) {
    x: u16 = 0,
    y: u16 = 0,

    pub const zero: Vector2 = .{
        .x = 0,
        .y = 0,
    };

    pub const default: Vector2 = .{
        .x = 0,
        .y = 0,
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

pub const Rectangle = packed struct(u64) {
    position: Vector2 = Vector2.zero,
    width: u16 = 0,
    height: u16 = 0,

    pub const zero: Rectangle = .{
        .position = .{
            .x = 0,
            .y = 0,
        },
        .width = 0,
        .height = 0,
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

pub const Player = packed struct(u96) {
    state: PlayerState = PlayerState.zero,
    role: PlayerRole = PlayerRole.zero,
    move: PlayerMove = PlayerMove.zero,
    score: PlayerScore = PlayerScore.zero,
    paddle: Paddle = Paddle.zero,
    padding: u16 = 0,

    pub const default_p1: Player = .{
        .state = .connected,
        .role = .player1,
        .move = .p1_noop,
        .score = ._0,
        .paddle = Paddle.default_left,
        .padding = 0,
    };

    pub const default_p2: Player = .{
        .state = .connected,
        .role = .player2,
        .move = .p2_noop,
        .score = ._0,
        .paddle = Paddle.default_right,
        .padding = 0,
    };

    pub const default_ai: Player = .{
        .state = .connected,
        .role = .player2,
        .move = .p2_noop,
        .score = ._0,
        .paddle = Paddle.default_right,
        .padding = 0,
    };

    pub const zero: Player = .{
        .state = PlayerState.zero,
        .role = PlayerRole.zero,
        .move = PlayerMove.zero,
        .score = PlayerScore.zero,
        .paddle = Paddle.zero,
        .padding = 0,
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

pub const Paddle = packed struct(u64) {
    hitbox: Rectangle = Rectangle.zero,

    pub const default_left: Paddle = .{
        .hitbox = .{
            .position = .{
                .x = 4,
                .y = 256 - 32,
            },
            .width = 8,
            .height = 64,
        },
    };

    pub const default_right: Paddle = .{
        .hitbox = .{
            .position = .{
                .x = 1020,
                .y = 256 - 32,
            },
            .width = 8,
            .height = 64,
        },
    };

    pub const default_dim: Paddle = .{
        .hitbox = .{
            .position = .{
                .x = 0,
                .y = 0,
            },
            .width = 8,
            .height = 64,
        },
    };

    pub const zero: Paddle = .{
        .hitbox = Rectangle.zero,
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

pub const Ball = packed struct(u128) {
    hitbox: Rectangle = Rectangle.zero,
    velocity: Vector2 = Vector2.zero,
    last_hit: Surface = Surface.zero,
    radius: u8 = 0,
    padding: u16 = 0,

    pub const default: Ball = .{
        .hitbox = Rectangle.zero,
        .velocity = Vector2.default,
        .last_hit = .none,
        .radius = 8,
        .padding = 0,
    };

    pub const zero: Ball = .{
        .hitbox = Rectangle.zero,
        .velocity = Vector2.zero,
        .last_hit = Surface.zero,
        .radius = 0,
        .padding = 0,
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

pub const Board = packed struct(u64) {
    dimension: Rectangle = Rectangle.zero,

    pub const zero: Board = .{
        .dimension = .{
            .position = .{
                .x = 0,
                .y = 0,
            },
            .width = 0,
            .height = 0,
        },
    };

    pub const default: Board = .{
        .dimension = .{
            .position = .{
                .x = 0,
                .y = 0,
            },
            .width = 1024,
            .height = 512,
        },
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

pub const PongState = packed struct(u30) {
    is_ball_hit: u1 = 0,
    is_ball_reset: u1 = 0,
    is_game_begin: u1 = 0,
    is_game_done: u1 = 0,
    is_game_paused: u1 = 0,
    is_game_playing: u1 = 0,
    is_player_1_ko: u1 = 0,
    is_player_1_mov: u1 = 0,
    is_player_1_ok: u1 = 0,
    is_player_1_seen: u1 = 0,
    is_player_2_ko: u1 = 0,
    is_player_2_mov: u1 = 0,
    is_player_2_ok: u1 = 0,
    is_player_2_seen: u1 = 0,
    player_1_missed: u8 = 0,
    player_2_missed: u8 = 0,

    pub const initial: PongState = .{
        .is_ball_hit = 0,
        .is_ball_reset = 0,
        .is_game_begin = 0,
        .is_game_done = 0,
        .is_game_paused = 0,
        .is_game_playing = 0,
        .is_player_1_ko = 0,
        .is_player_1_mov = 0,
        .is_player_1_ok = 0,
        .is_player_1_seen = 0,
        .is_player_2_ko = 0,
        .is_player_2_mov = 0,
        .is_player_2_ok = 0,
        .is_player_2_seen = 0,
        .player_1_missed = 0,
        .player_2_missed = 0,
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

pub const Pong = packed struct(u512) {
    player1: Player = Player.default_p1,
    player2: Player = Player.default_ai,
    ball: Ball = Ball.default,
    board: Board = Board.default,
    prev_state: PongState = PongState.initial,
    curr_state: PongState = PongState.initial,
    kind: PongKind = .default,
    timestamp: u64 = 0,

    pub const default: Pong = .{
        .player1 = Player.default_p1,
        .player2 = Player.default_ai,
        .ball = Ball.default,
        .board = Board.default,
        .prev_state = PongState.initial,
        .curr_state = PongState.initial,
        .kind = .local_ai,
        .timestamp = 0,
    };

    pub const zero: Pong = .{
        .player1 = Player.zero,
        .player2 = Player.zero,
        .ball = Ball.zero,
        .board = Board.zero,
        .prev_state = PongState.initial,
        .curr_state = PongState.initial,
        .kind = .none,
        .timestamp = 0,
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

pub const Message = packed struct(u1024) {
    prev_state: Pong = Pong.zero,
    curr_state: Pong = Pong.zero,

    pub const zero: Message = .{
        .prev_state = Pong.zero,
        .curr_state = Pong.zero,
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

pub const MessageTotalBytes: usize = @sizeOf(Message);
pub const MessageBackingInteger: type = u1024;
