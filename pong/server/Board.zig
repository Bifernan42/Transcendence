// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Board.zig                                          :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/30 14:39:21 by pollivie          #+#    #+#             //
//   Updated: 2025/01/30 14:39:22 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const lib = @import("libpong");
const Board = @This();

board: lib.Board = lib.Board.default,

pub fn init(width: u32, height: u32) Board {
    return .{
        .board = lib.Board.init(.{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(width),
            .height = @floatFromInt(height),
        }),
    };
}

pub fn getCenter(self: Board) rl.Vector2 {
    return self.board.getCenter();
}

pub const default: Board = .{
    .board = lib.Board.default,
};
