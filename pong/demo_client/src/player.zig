// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   player.zig                                         :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/16 09:24:43 by pollivie          #+#    #+#             //
//   Updated: 2025/01/16 09:24:44 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const rl = @import("raylib");
const Paddle = @import("paddle.zig").Paddle;
const Direction2d = @import("paddle.zig").Direction2D;
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
