// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Pong.zig                                           :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/30 14:39:00 by pollivie          #+#    #+#             //
//   Updated: 2025/01/30 14:39:00 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const lib = @import("libpong");
const Player = @import("Player.zig");
const Board = @import("Board.zig");
const Ball = @import("Ball.zig");
const Paddle = @import("Paddle.zig");
const Pong = @This();

pub const AiDifficulty = enum(u8) {
    recruit = 4,
    normal = 8,
    commando = 12,
    veteran = 16,
};

pub const PongKind = enum {
    local_ai,
    local_mp,
    remote_mp,
    ai_ai,
};

pub const PongOptions = struct {
    ai_difficulty: AiDifficulty = .normal,
    ai_fallback: ?bool = false,
    ball_hitbox_width: u32 = 12,
    ball_hitbox_height: u32 = 12,
    ball_radius: u32 = 8,
    ball_speed: u32 = 200,
    board_width: u32 = 1024,
    board_height: u32 = 512,
    paddle_width: u32 = 16,
    paddle_height: u32 = 64,
    paddle_speed: u32 = 8,
    player1_name: []const u8 = "p1",
    player2_name: []const u8 = "p2",
    pong_kind: PongKind = .local_mp,

    pub const default: PongOptions = .{
        .ai_difficulty = .normal,
        .ai_fallback = false,
        .ball_hitbox_width = 12,
        .ball_hitbox_height = 12,
        .ball_radius = 8,
        .ball_speed = 200,
        .board_width = 1024,
        .board_height = 512,
        .paddle_width = 16,
        .paddle_height = 64,
        .paddle_speed = 8,
        .player1_name = "p1",
        .player2_name = "p2",
        .pong_kind = .local_mp,
    };
};

player1: Player = Player.default,
player2: Player = Player.default,
board: Board = Board.default,
ball: Ball = Ball.default,
pong: lib.Pong = lib.Pong.default,

pub fn init(options: PongOptions) Pong {
    const paddle1: lib.Paddle = .init(.{
        .x = 4,
        .y = 224,
        .width = @floatFromInt(options.paddle_width),
        .height = @floatFromInt(options.paddle_height),
    });

    const paddle2: lib.Paddle = .init(.{
        .x = 1004,
        .y = 224,
        .width = @floatFromInt(options.paddle_width),
        .height = @floatFromInt(options.paddle_height),
    });

    const player1_inner: lib.Player = .init(.player1, paddle1);
    const player2_inner: lib.Player = .init(.player2, paddle2);
    const board: Board = .init(options.board_width, options.board_height);
    const ball = Ball.init(board.getCenter(), @floatFromInt(options.ball_radius), @floatFromInt(options.ball_speed));
    const pong: lib.Pong = .init(player1_inner, player2_inner, board.board, ball.ball);

    return .{
        .player1 = Player.init(options.player1_name, player1_inner),
        .player2 = Player.init(options.player2_name, player2_inner),
        .board = board,
        .ball = ball,
        .pong = pong,
    };
}
