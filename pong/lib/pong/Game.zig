// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Game.zig                                           :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/30 11:07:59 by pollivie          #+#    #+#             //
//   Updated: 2025/01/30 11:08:00 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");

const rg = @import("raygui");
const rl = @import("raylib");

const Ball = @import("Ball.zig").Ball;
const Board = @import("Board.zig").Board;
const Paddle = @import("Paddle.zig").Paddle;
const Player = @import("Player.zig").Player;

pub const Kind = enum(u8) {
    ai_ai,
    local_ai,
    local_mp,
    remote_mp,
};

pub const Rules = packed struct(u128) {
    paddle_speed: f32,
    ball_speed: f32,
    max_score: u8,
    game_kind: Kind,
    tickrate: u16,
    _padding: u32,
};

pub const Game = packed struct(u1024) {
    rules: Rules,
    player1: Player,
    player2: Player,
    paddle1: Paddle,
    paddle2: Paddle,
    board: Board,
    ball: Ball,
    _padding: u128,
};
