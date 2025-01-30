// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Board.zig                                          :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/30 13:39:55 by pollivie          #+#    #+#             //
//   Updated: 2025/01/30 13:40:03 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const root = @import("root.zig");
pub const Board = @This();

dimension: rl.Rectangle = root.rect_default,

pub fn init(dimension: rl.Rectangle) Board {
    return .{
        .dimension = dimension,
    };
}

pub fn getCenter(self: Board) rl.Vector2 {
    return .{
        .x = self.dimension.width / 2.0,
        .y = self.dimension.height / 2.0,
    };
}

pub fn drawBoardLines(self: Board, thickness: f32, color: rl.Color) void {
    rl.drawRectangleLinesEx(self.dimension, thickness, color);
}

pub fn drawBoardBackground(self: Board, color: rl.Color) void {
    rl.drawRectangleRec(self.dimension, color);
}

pub fn drawBoardCenterStripLine(self: Board, number_of_strip: u8, fg: rl.Color, bg: rl.Color) void {
    const total_length = self.dimension.height;
    const strip_length = @divExact(total_length, number_of_strip);

    const start: rl.Vector2 = .{
        .x = @divExact(self.dimension.width, 2),
        .y = 0,
    };

    for (0..number_of_strip) |n| {
        const color: rl.Color = if (@mod(n, 2) == 0) bg else fg;

        const from: rl.Vector2 = .{
            .x = start.x,
            .y = strip_length * @as(f32, @floatFromInt(n)),
        };

        const to: rl.Vector2 = .{
            .x = start.x,
            .y = from.y + strip_length,
        };

        rl.drawLineV(from, to, color);
    }
}

pub fn update(self: *Board, width: u32, height: u32) void {
    self.dimension.width = @floatFromInt(width);
    self.dimension.height = @floatFromInt(height);
}

pub const default: Board = .{
    .dimension = root.rect_default,
};
