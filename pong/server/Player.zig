// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Player.zig                                         :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/30 14:39:08 by pollivie          #+#    #+#             //
//   Updated: 2025/01/30 14:39:08 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const lib = @import("libpong");
const Player = @This();

name: []const u8 = "",
player: lib.Player = .{},
score: u8 = 0,

pub fn init(name: []const u8, player: lib.Player) Player {
    return .{
        .name = name,
        .player = player,
        .score = 0,
    };
}

pub const default: Player = .{
    .name = "",
    .player = lib.Player.default,
    .score = 0,
};
