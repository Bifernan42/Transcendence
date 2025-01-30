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

pub fn init(name: []const u8, player: lib.Player) Player {
    return .{
        .name = name,
        .player = player,
    };
}

pub const default: Player = .{
    .name = "",
    .player = lib.Player.default,
};
