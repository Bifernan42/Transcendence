// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Player.zig                                         :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/30 13:39:41 by pollivie          #+#    #+#             //
//   Updated: 2025/01/30 13:39:50 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const rl = @import("raylib");
const Action = @import("root.zig").Action;
const Paddle = @import("Paddle.zig");
const Role = @import("root.zig").Role;
const Player = @This();

client_id: u32 = 0,
score: u8 = 0,
role: Role = .nobody,
action: Action = Action.default,
paddle: Paddle = Paddle.default,

pub fn init(role: Role, paddle: Paddle) Player {
    return .{
        .role = role,
        .paddle = paddle,
        .client_id = @intFromEnum(role),
    };
}

pub fn update(self: *Player, player: Player) void {
    self.client_id = @intFromEnum(player.role);
    self.score = player.score;
    self.role = player.role;
    self.paddle = player.paddle;
}

pub const default: Player = .{
    .client_id = 0,
    .score = 0,
    .role = Role.default,
    .action = Action.default,
    .paddle = Paddle.default,
};
