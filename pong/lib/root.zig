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
pub const rl = @import("raylib");

pub const Ball = @import("Ball.zig");
pub const Board = @import("Board.zig");
pub const Paddle = @import("Paddle.zig");
pub const Player = @import("Player.zig");
pub const Pong = @import("Pong.zig");

pub const vec2_default: rl.Vector2 = .{
    .x = 0,
    .y = 0,
};

pub const rect_default: rl.Rectangle = .{
    .x = 0,
    .y = 0,
    .width = 0,
    .height = 0,
};

pub const Role = enum(u8) {
    nobody,
    player1,
    player2,
    spectator,

    pub const default: Role = .nobody;
};

pub const Action = enum(u8) {
    on_key_press_nothing,
    on_key_press_p1_up,
    on_key_press_p1_down,
    on_key_press_p2_up,
    on_key_press_p2_down,

    pub const default: Action = .on_key_press_nothing;
};

pub const Status = enum(u8) {
    lobby,
    playing,
    done,
    pausing,
    resuming,
    failure,

    pub const default: Status = .lobby;
};

// Ce que le serveur renvoie tout le temps
pub const Response = packed struct(u512) {
    screen_width: u32 = 1024,
    screen_height: u32 = 512,

    ball_position_x: f32 = 512,
    ball_position_y: f32 = 256,
    ball_radius: f32 = 8,

    paddle_width: u32 = 16,
    paddle_height: u32 = 64,

    player1_paddle_x: f32 = 4,
    player1_paddle_y: f32 = 224,

    player2_paddle_x: f32 = 1004,
    player2_paddle_y: f32 = 224,

    player1_score: u8 = 0,
    player2_score: u8 = 0,

    status: Status = .lobby,
    timestamp: i64 = 0,
    _padding: u72 = 0,

    pub fn init(from: Response) Response {
        return .{
            .screen_width = from.screen_width,
            .screen_height = from.screen_height,
            .ball_position_x = from.ball_position_x,
            .ball_position_y = from.ball_position_y,
            .ball_radius = from.ball_radius,
            .paddle_width = from.paddle_width,
            .paddle_height = from.paddle_height,
            .player1_paddle_x = from.player1_paddle_x,
            .player1_paddle_y = from.player1_paddle_y,
            .player2_paddle_x = from.player2_paddle_x,
            .player2_paddle_y = from.player2_paddle_y,
            .player1_score = from.player1_score,
            .player2_score = from.player2_score,
            .status = from.status,
            .timestamp = from.timestamp,
            ._padding = 0,
        };
    }

    pub fn toBytes(self: *Response) []u8 {
        return std.mem.asBytes(self);
    }

    pub fn fromBytes(self: *Response, bytes: []const u8) void {
        self.* = std.mem.bytesToValue(Response, bytes);
    }

    pub const default: Response = .{
        .screen_width = 1024,
        .screen_height = 512,

        .ball_position_x = 512,
        .ball_position_y = 256,
        .ball_radius = 8,

        .paddle_width = 16,
        .paddle_height = 64,

        .player1_paddle_x = 4,
        .player1_paddle_y = 224,

        .player2_paddle_x = 1004,
        .player2_paddle_y = 224,

        .player1_score = 0,
        .player2_score = 0,

        .status = .lobby,
        .timestamp = 0,
        ._padding = 0,
    };
};

// Ce que le client envoie tout le temps.
pub const Request = packed struct(u128) {
    client_id: u32 = 0,
    p1_action: Action = .on_key_press_nothing,
    p2_action: Action = .on_key_press_nothing,
    timestamp: i64 = 0,
    _padding: u16 = 0,

    pub fn init(from: Request) Request {
        return .{
            .client_id = from.client_id,
            .p1_action = from.p1_action,
            .p2_action = from.p2_action,
            .timestamp = from.timestamp,
            ._padding = from._padding,
        };
    }

    pub fn toBytes(self: *Request) []u8 {
        return std.mem.asBytes(self);
    }

    pub fn fromBytes(self: *Request, bytes: []const u8) void {
        self.* = std.mem.bytesToValue(Request, bytes);
    }

    pub const default: Request = .{
        .client_id = 0,
        .p1_action = Action.default,
        .p2_action = Action.default,
        .timestamp = 0,
        ._padding = 0,
    };
};

pub fn getBufferSize(comptime capacity: usize, comptime T: type) usize {
    return capacity * @sizeOf(T);
}
