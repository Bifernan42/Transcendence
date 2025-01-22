// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   ball.zig                                           :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/16 09:34:08 by pollivie          #+#    #+#             //
//   Updated: 2025/01/16 09:34:08 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const rl = @import("raylib");
pub const Ball = @This();

hitbox: rl.Rectangle,
center: rl.Vector2,
radius: f32,
velocity: rl.Vector2,
speed_px_per_s: f32,
bg: rl.Color,
fg: rl.Color,

pub const SurfaceHit = enum {
    left,
    right,
    up,
    down,
    lpad,
    rpad,
};

pub fn init(radius: f32, center: rl.Vector2, bg: rl.Color, fg: rl.Color) Ball {
    var randomizer = std.Random.DefaultPrng.init(0);
    const rand = randomizer.random();
    const multiplier: f32 = if (std.Random.float(rand, f32) <= 0.5) -1.0 else 1.0;
    const direction_y = multiplier * std.Random.float(rand, f32);
    return .{
        .hitbox = rl.Rectangle{
            .x = center.x - radius,
            .y = center.y - radius,
            .width = radius * 2.2,
            .height = radius * 2.2,
        },
        .center = center,
        .radius = radius,
        .velocity = .{ .x = 1.0, .y = direction_y },
        .speed_px_per_s = 300,
        .bg = bg,
        .fg = fg,
    };
}

pub fn drawLines(self: Ball) void {
    rl.drawCircleLinesV(self.center, self.radius, self.fg);
}

pub fn drawBackground(self: Ball) void {
    rl.drawCircleV(self.center, self.radius, self.bg);
}

pub fn drawHitBox(self: Ball) void {
    rl.drawRectangleLinesEx(self.hitbox, 1, rl.Color.pink);
}

pub fn move(self: *Ball, delta_time: f32, bounds: rl.Rectangle, paddle1: rl.Rectangle, paddle2: rl.Rectangle) ?SurfaceHit {
    var hit: ?SurfaceHit = null;

    // Update the ball's position based on velocity and speed
    self.center.x += self.velocity.x * self.speed_px_per_s * delta_time;
    self.center.y += self.velocity.y * self.speed_px_per_s * delta_time;

    // Update hitbox to match new position
    self.hitbox.x = self.center.x - self.radius;
    self.hitbox.y = self.center.y - self.radius;

    // Handle collisions with top and bottom walls
    if (self.center.y - self.radius < 0) {
        self.velocity.y *= -1; // Reverse Y direction
        hit = .up;
    } else if (self.center.y + self.radius > bounds.height) {
        self.velocity.y *= -1; // Reverse Y direction
        hit = .down;
    }

    // Handle collisions with paddles
    if (rl.checkCollisionRecs(self.hitbox, paddle1)) {
        self.velocity.x *= -1; // Reverse X direction
        self.velocity.x *= 1.1; // Optional: Increase speed slightly
        hit = .lpad;
    } else if (rl.checkCollisionRecs(self.hitbox, paddle2)) {
        self.velocity.x *= -1; // Reverse X direction
        self.velocity.x *= 1.1; // Optional: Increase speed slightly
        hit = .rpad;
    }

    // Handle collisions with left and right bounds (out of play)
    if (self.center.x - self.radius < 0) {
        hit = .left;
        self.reset(bounds);
    } else if (self.center.x + self.radius > bounds.width) {
        hit = .right;
        self.reset(bounds);
    }

    return hit;
}

// Reset the ball to the center
pub fn reset(self: *Ball, bounds: rl.Rectangle) void {
    var randomizer = std.Random.DefaultPrng.init(0);
    const rand = randomizer.random();
    const multiplier: f32 = if (std.Random.float(rand, f32) <= 0.5) -1.0 else 1.0;
    const direction_y = multiplier * std.Random.float(rand, f32);

    self.center = .{
        .x = bounds.width / 2,
        .y = bounds.height / 2,
    };
    self.velocity = .{
        .x = std.math.sign(self.velocity.x) * 1.0, // Ensure it moves in the correct direction
        .y = direction_y, // Randomize vertical direction slightly
    };
}
