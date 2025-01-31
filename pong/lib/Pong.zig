// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Pong.zig                                           :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/30 13:37:55 by pollivie          #+#    #+#             //
//   Updated: 2025/01/30 13:37:55 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");

const rg = @import("raygui");
const rl = @import("raylib");

const Ball = @import("Ball.zig");
const Board = @import("Board.zig");
const Paddle = @import("Paddle.zig");
const Player = @import("Player.zig");
const Response = @import("root.zig").Response;

const Pong = @This();

player1: Player,
player2: Player,
board: Board,
ball: Ball,

pub fn init(p1: Player, p2: Player, board: Board, ball: Ball) Pong {
    return .{
        .player1 = p1,
        .player2 = p2,
        .board = board,
        .ball = ball,
    };
}

pub fn drawBoard(self: Pong, number_of_strip: u8, thickness: f32, fg: rl.Color, bg: rl.Color) void {
    self.board.drawBoardLines(thickness, fg);
    self.board.drawBoardBackground(bg);
    self.board.drawBoardCenterStripLine(number_of_strip, fg, bg);
}

pub fn drawPaddles(self: Pong, thickness: f32, fg: rl.Color, bg: rl.Color) void {
    self.player1.paddle.drawPaddleLines(thickness, fg);
    self.player1.paddle.drawPaddleBackground(bg);
    self.player2.paddle.drawPaddleLines(thickness, fg);
    self.player2.paddle.drawPaddleBackground(bg);
}

pub fn drawBall(self: Pong, thickness: ?f32, fg: rl.Color, bg: rl.Color) void {
    if (thickness) |v| {
        self.ball.drawHitBox(v, fg);
    }
    self.ball.drawBallLines(fg);
    self.ball.drawBallBackground(bg);
}

pub fn update(self: *Pong, response: *const Response) void {
    self.player1.update(.{
        .client_id = self.player1.client_id,
        .score = response.player1_score,
        .role = self.player1.role,
        .action = .on_key_press_nothing,
        .paddle = Paddle.init(.{
            .x = response.player1_paddle_x,
            .y = response.player1_paddle_y,
            .width = @floatFromInt(response.paddle_width),
            .height = @floatFromInt(response.paddle_height),
        }),
    });

    self.player2.update(.{
        .client_id = self.player2.client_id,
        .score = response.player2_score,
        .role = self.player2.role,
        .action = .on_key_press_nothing,
        .paddle = Paddle.init(.{
            .x = response.player2_paddle_x,
            .y = response.player2_paddle_y,
            .width = @floatFromInt(response.paddle_width),
            .height = @floatFromInt(response.paddle_height),
        }),
    });

    self.board.update(
        response.screen_width,
        response.screen_height,
    );

    self.ball.update(.{
        .x = response.ball_position_x,
        .y = response.ball_position_y,
    }, response.ball_radius);
}

pub const default: Pong = .{
    .player1 = Player.default,
    .player2 = Player.default,
    .board = Board.default,
    .ball = Ball.default,
};
