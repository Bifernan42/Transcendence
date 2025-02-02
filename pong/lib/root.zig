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
const rl = @import("raylib");
pub const Pong = @import("Pong.zig");
pub const Config = @import("Config.zig");
pub const PongOptions = Config.PongOptions;

pub const PlayerStatus = enum(u8) {
    absent,
    waiting,
    ready,
    scored,

    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try std.json.stringify(self, .{ .whitespace = .indent_2 }, writer);
    }
};

pub const PlayerKind = enum(u8) {
    player1,
    player2,
    spectator,
    bot,

    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try std.json.stringify(self, .{ .whitespace = .indent_2 }, writer);
    }
};

pub const PlayerAction = enum(u8) {
    pressed_none,
    pressed_up,
    pressed_down,

    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try std.json.stringify(self, .{ .whitespace = .indent_2 }, writer);
    }
};

pub const Response = packed struct(u512) {
    board_width: u32,
    board_height: u32,

    paddle_width: u32,
    paddle_height: u32,

    player1_x: u32,
    player1_y: u32,

    player2_x: u32,
    player2_y: u32,

    ball_radius: u32,
    ball_x: u32,
    ball_y: u32,
    player1_score: u8,
    player2_score: u8,
    player1_status: PlayerStatus,
    player2_status: PlayerStatus,
    timestamp: i64,
    _padding: u64,

    pub fn init() Response {
        return .{
            .board_width = 0,
            .board_height = 0,
            .paddle_width = 0,
            .paddle_height = 0,
            .player1_x = 0,
            .player1_y = 0,
            .player2_x = 0,
            .player2_y = 0,
            .ball_radius = 0,
            .ball_x = 0,
            .ball_y = 0,
            .player1_score = 0,
            .player2_score = 0,
            .player1_status = .absent,
            .player2_status = .absent,
            .timestamp = 0,
            ._padding = 0,
        };
    }

    pub fn asBytes(self: *Response) []u8 {
        return std.mem.asBytes(self);
    }

    pub fn fromBytes(self: *Response, bytes: []const u8) void {
        self.* = std.mem.bytesAsValue(Response, bytes[0..]).*;
    }

    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try std.json.stringify(self, .{ .whitespace = .indent_2 }, writer);
    }
};

pub const Request = packed struct(u128) {
    client_id: u32,
    player1_action: PlayerAction,
    player2_action: PlayerAction,
    timestamp: i64,
    _padding: u16,

    pub fn init() Request {
        return .{
            .client_id = 0,
            .player1_action = PlayerAction.pressed_none,
            .player2_action = PlayerAction.pressed_none,
            .timestamp = 0,
            ._padding = 0,
        };
    }

    pub fn asBytes(self: *Request) []u8 {
        return std.mem.asBytes(self);
    }

    pub fn fromBytes(self: *Request, bytes: []const u8) void {
        self.* = std.mem.bytesAsValue(Request, bytes[0..]).*;
    }

    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try std.json.stringify(self, .{ .whitespace = .indent_2 }, writer);
    }
};

pub fn getBufferSize(capacity: usize, comptime T: type) usize {
    return capacity * @sizeOf(T);
}

pub const default_vector2: rl.Vector2 = .{
    .x = 0,
    .y = 0,
};

pub const default_rectangle: rl.Rectangle = .{
    .x = 0,
    .y = 0,
    .width = 0,
    .height = 0,
};
