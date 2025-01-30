// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Player.zig                                         :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/30 11:07:25 by pollivie          #+#    #+#             //
//   Updated: 2025/01/30 11:07:25 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");

pub const Role = enum(u8) {
    is_undefined,
    is_player1,
    is_player2,
    is_ai_bot,
    is_spectator,
};

pub const Action = enum(u8) {
    press_none,
    press_up,
    press_down,
    press_pause,
    press_play,
};

pub const Status = enum(u8) {
    accepted,
    registered,
    disconnected,
    playing,
    failure,
    success,
};

pub const Move = packed struct(u72) {
    action: Action,
    timestamp: u64,
};

pub const Player = packed struct(u128) {
    state: Status,
    role: Role,
    move: Move,
    _padding: u40,
};
