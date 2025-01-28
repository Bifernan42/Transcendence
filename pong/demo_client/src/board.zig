// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   board.zig                                          :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/16 09:40:40 by pollivie          #+#    #+#             //
//   Updated: 2025/01/16 09:40:41 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const rl = @import("raylib");
pub const Board = @This();

dimension: rl.Rectangle,
bg: rl.Color,
fg: rl.Color,

pub fn init(dimension: rl.Rectangle, bg: rl.Color, fg: rl.Color) Board {
    return .{
        .dimension = dimension,
        .bg = bg,
        .fg = fg,
    };
}

pub fn getCenter(self: Board) rl.Vector2 {
    return .{
        .x = self.dimension.x,
        .y = self.dimension.y,
    };
}

pub fn drawBoardLines(self: Board) void {
    rl.drawRectangleLinesEx(self.dimension, 3.0, self.fg);
}

pub fn drawBoardBackground(self: Board) void {
    rl.drawRectangleRec(self.dimension, self.bg);
}

pub fn drawBoardMiddleLine(self: Board) void {
    const total_length = self.dimension.height;
    const number_of_strips = 128;
    const strip_length = @divExact(total_length, number_of_strips);

    const start: rl.Vector2 = .{
        .x = @divExact(self.dimension.width, 2),
        .y = 0,
    };

    for (0..number_of_strips) |n| {
        const color: rl.Color = if (@mod(n, 2) == 0) self.bg else self.fg;

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
