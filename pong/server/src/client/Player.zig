// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Player.zig                                         :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/28 11:53:49 by pollivie          #+#    #+#             //
//   Updated: 2025/01/28 11:53:53 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const rl = @import("raylib");
const Paddle = @import("Paddle.zig").Paddle;
const Ball = @import("Ball.zig");
const Direction2d = @import("Paddle.zig").Direction2D;
pub const Player = @This();

name: []const u8,
paddle: Paddle,
color: rl.Color,
score: u8,
movement_speed: f32,

pub fn init(name: []const u8, paddle: Paddle, color: rl.Color) Player {
    return .{
        .name = name,
        .paddle = paddle,
        .color = color,
        .score = 0,
        .movement_speed = 8,
    };
}

pub fn move(self: *Player, comptime direction: Direction2d, bounds: rl.Rectangle) void {
    self.paddle.move(direction, self.movement_speed, bounds);
}

pub fn getPosition(self: *const Player) rl.Vector2 {
    return .{
        .x = self.paddle.dimension.x,
        .y = self.paddle.dimension.y,
    };
}

pub fn moveAi(self: *Player, ball: *Ball, bounds: rl.Rectangle) void {
    const paddle_center = self.paddle.dimension.y + (self.paddle.dimension.height / 2);
    const ball_center = ball.center.y;
    const ball_speed = @abs(ball.velocity.y * 8); // Magic number.

    const distance = @abs(paddle_center - ball_center);

    const scaled_speed = ball_speed * (1 + distance / bounds.height);

    if (ball.velocity.x > 0) {
        if (paddle_center < ball_center) {
            self.paddle.dimension.y += scaled_speed;
        } else if (paddle_center > ball_center) {
            self.paddle.dimension.y -= scaled_speed;
        }
    } else {
        if (ball.velocity.y > 0) {
            if (ball_center > paddle_center) {
                self.paddle.dimension.y += scaled_speed;
            } else {
                self.paddle.dimension.y -= scaled_speed;
            }
        } else if (ball.velocity.y < 0) {
            if (ball_center < paddle_center) {
                self.paddle.dimension.y -= scaled_speed;
            } else {
                self.paddle.dimension.y += scaled_speed;
            }
        }
    }

    if (self.paddle.dimension.y < 0) {
        self.paddle.dimension.y = 0;
    } else if (self.paddle.dimension.y + self.paddle.dimension.height > bounds.height) {
        self.paddle.dimension.y = bounds.height - self.paddle.dimension.height;
    }
}
