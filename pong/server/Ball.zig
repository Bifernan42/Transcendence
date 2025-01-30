// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Ball.zig                                           :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/30 14:39:13 by pollivie          #+#    #+#             //
//   Updated: 2025/01/30 14:39:14 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const rg = @import("raygui");
const rl = @import("raylib");
const lib = @import("libpong");
const Ball = @This();

ball: lib.Ball = lib.Ball.default,
velocity: rl.Vector2 = lib.vec2_default,
speed: f32 = 0.0,

pub fn init(position: rl.Vector2, radius: f32, speed: f32) Ball {
    return .{
        .ball = lib.Ball.init(position, radius),
        .speed = speed,
        .velocity = .{ .x = 0, .y = 0 },
    };
}

pub fn reset(self: *Ball, center: rl.Vector2) void {
    self.ball.position = center;
}

pub fn move(self: *Ball, position: rl.Vector2) void {
    self.ball.update(position, self.ball.radius);
}

pub fn accelerate(self: *Ball, amount: f32) void {
    self.speed += amount;
}

pub fn slowdown(self: *Ball, amount: f32) void {
    self.speed -= amount;
}

pub const default: Ball = .{
    .ball = lib.Ball.default,
    .velocity = lib.vec2_default,
    .speed = 0.0,
};
