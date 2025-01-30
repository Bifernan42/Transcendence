// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Paddle.zig                                         :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/30 14:39:30 by pollivie          #+#    #+#             //
//   Updated: 2025/01/30 14:39:31 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const lib = @import("libpong");
const Paddle = @This();

paddle: lib.Paddle,

pub fn init(width: u32, height: u32) Paddle {
    return .{
        .paddle = lib.Paddle.init(.{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(width),
            .height = @floatFromInt(height),
        }),
    };
}

pub fn getCenter(self: Paddle) rl.Vector2 {
    return .{
        .x = self.paddle.dimension.width / 2,
        .y = self.paddle.dimension.height / 2,
    };
}
