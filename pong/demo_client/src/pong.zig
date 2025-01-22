// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   pong.zig                                           :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/16 09:46:17 by pollivie          #+#    #+#             //
//   Updated: 2025/01/16 09:46:18 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const rl = @import("raylib");
const builtin = @import("builtin");
pub const Pong = @This();
const Player = @import("player.zig").Player;
const Paddle = @import("paddle.zig").Paddle;
const Ball = @import("ball.zig").Ball;
const Board = @import("board.zig").Board;

pub const PongState = enum {
    playing,
    paused,
    finished,
};

pub const PongError = error{
    InvalidState,
};

player1: Player,
player2: Player,
board: Board,
ball: Ball,

pub fn init(player1: Player, player2: Player, board: Board, ball: Ball) Pong {
    return .{
        .player1 = player1,
        .player2 = player2,
        .board = board,
        .ball = ball,
    };
}

pub fn drawBoard(self: Pong) void {
    self.board.drawBoardBackground();
    self.board.drawBoardMiddleLine();
    self.board.drawBoardLines();
}

pub fn drawBall(self: Pong) void {
    self.ball.drawBackground();
    self.ball.drawLines();
    if (builtin.mode == .Debug) {
        self.ball.drawHitBox();
    }
}

pub fn drawPaddles(self: Pong) void {
    self.player1.paddle.drawBackground(self.player1.color);
    self.player1.paddle.drawLines(self.board.fg);
    self.player2.paddle.drawBackground(self.player2.color);
    self.player2.paddle.drawLines(self.board.fg);
}
