// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Paddle.zig                                         :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/30 13:40:21 by pollivie          #+#    #+#             //
//   Updated: 2025/01/30 13:40:34 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const rl = @import("raylib");
const root = @import("root.zig");
const Response = @import("root.zig").Response;
pub const Paddle = @This();

dimension: rl.Rectangle,

pub fn init(dimension: rl.Rectangle) Paddle {
    return .{
        .dimension = dimension,
    };
}

pub fn drawPaddleLines(self: Paddle, thickness: f32, color: rl.Color) void {
    rl.drawRectangleLinesEx(self.dimension, thickness, color);
}

pub fn drawPaddleBackground(self: Paddle, color: rl.Color) void {
    rl.drawRectangleRec(self.dimension, color);
}

pub fn update(self: *Paddle, position: rl.Vector2) void {
    self.dimension.x = position.x;
    self.dimension.y = position.y;
}
