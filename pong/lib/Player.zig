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

client_id: u32,
score: u8,
role: Role,
action: Action,
paddle: Paddle,

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
