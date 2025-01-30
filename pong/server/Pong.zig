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

player1: Player,
player2: Player,
board: Board,
ball: Ball,
pong: lib.Pong,

pub fn init(options: PongOptions) Pong {
    _ = options;
    return .{};
}
