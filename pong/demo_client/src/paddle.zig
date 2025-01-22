// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   paddle.zig                                         :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/16 09:26:09 by pollivie          #+#    #+#             //
//   Updated: 2025/01/16 09:26:09 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const rl = @import("raylib");
pub const Paddle = @This();

dimension: rl.Rectangle,
direction: rl.Vector2,
velocity: f32,

pub const Direction2D = enum {
    up,
    down,
    left,
    right,
    none,
};

pub fn init(dimension: rl.Rectangle, velocity: f32) Paddle {
    return .{
        .dimension = dimension,
        .velocity = velocity,
        .direction = .{},
    };
}

pub fn drawLines(self: Paddle, fg: rl.Color) void {
    rl.drawRectangleLinesEx(self.dimension, 2, fg);
}

pub fn drawBackground(self: Paddle, bg: rl.Color) void {
    rl.drawRectangleRec(self.dimension, bg);
}

fn moveOrClip(self: *Paddle, new_position: rl.Vector2, bounds: rl.Rectangle) void {
    const new_paddle_pos: rl.Rectangle = .{
        .x = new_position.x,
        .y = new_position.y,
        .width = self.dimension.width,
        .height = self.dimension.height,
    };

    if (new_paddle_pos.y >= 0 and new_position.y <= (bounds.height - self.dimension.height)) {
        self.dimension = new_paddle_pos;
    }
}

pub fn move(self: *Paddle, comptime direction: Direction2D, amount: f32, bounds: rl.Rectangle) void {
    switch (direction) {
        .up => {
            self.moveOrClip(
                .{
                    .x = self.dimension.x,
                    .y = self.dimension.y - amount, // Move up
                },
                bounds,
            );
        },
        .down => {
            self.moveOrClip(
                .{
                    .x = self.dimension.x,
                    .y = self.dimension.y + amount, // Move down
                },
                bounds,
            );
        },
        else => @compileError("Invalid movement direction."),
    }
}
