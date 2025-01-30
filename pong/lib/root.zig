// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   root.zig                                           :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/30 10:09:15 by pollivie          #+#    #+#             //
//   Updated: 2025/01/30 10:09:15 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");

pub const rg = @import("raygui");
pub const rl = @import("raygui");

pub const Ball = @import("Ball.zig");
pub const Board = @import("Board.zig");
pub const Paddle = @import("Paddle.zig");
pub const Player = @import("Player.zig");
pub const Pong = @import("Pong.zig");

pub const Role = enum(u8) {
    nobody,
    player1,
    player2,
    spectator,
};

pub const Action = enum(u8) {
    on_key_press_nothing,
    on_key_press_p1_up,
    on_key_press_p1_down,
    on_key_press_p2_up,
    on_key_press_p2_down,
};

pub const Status = enum(u8) {
    lobby,
    playing,
    done,
    pausing,
    resuming,
    failure,
};

// Ce que le serveur renvoie tout le temps
pub const Response = packed struct(u512) {
    screen_width: u32,
    screen_height: u32,

    ball_position_x: f32,
    ball_position_y: f32,
    ball_radius: f32,

    paddle_width: u32,
    paddle_height: u32,

    player1_paddle_x: f32,
    player1_paddle_y: f32,

    player2_paddle_x: f32,
    player2_paddle_y: f32,

    player1_score: u8,
    player2_score: u8,

    status: Status,
    timestamp: i64,
    _padding: u72,
};

// Ce que le client envoie tout le temps.
pub const Request = packed struct(u128) {
    client_id: u32,
    p1_action: Action,
    p2_action: Action,
    timestamp: i64,
    _padding: u16,
};
