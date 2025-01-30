// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Ball.zig                                           :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/30 13:40:06 by pollivie          #+#    #+#             //
//   Updated: 2025/01/30 13:40:14 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const rl = @import("raylib");
const root = @import("root.zig");
pub const Ball = @This();

position: rl.Vector2 = root.vec2_default,
radius: f32 = 0.0,

pub fn init(position: rl.Vector2, radius: f32) Ball {
    return .{
        .position = position,
        .radius = radius,
    };
}

pub fn getHitbox(self: Ball) rl.Rectangle {
    return .{
        .x = self.position.x - self.radius,
        .y = self.position.y - self.radius,
        .width = self.radius * 2.5,
        .height = self.radius * 2.5,
    };
}

pub fn drawBallLines(self: Ball, color: rl.Color) void {
    rl.drawCircleLinesV(self.position, self.radius, color);
}

pub fn drawBallBackground(self: Ball, color: rl.Color) void {
    rl.drawCircleV(self.position, self.position, color);
}

pub fn drawHitBox(self: Ball, thickness: f32, color: rl.Color) void {
    rl.drawRectangleLinesEx(self.getHitbox(), thickness, color);
}

pub fn update(self: *Ball, position: rl.Vector2, radius: f32) void {
    self.position.x = position.x;
    self.position.y = position.y;
    self.radius = radius;
}

pub const default: Ball = .{
    .position = .{ .x = 0, .y = 0 },
    .radius = 0.0,
};
