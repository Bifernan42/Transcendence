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

pub const PlayerStatus = enum(u8) {
    unavailable,
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

pub const Role = enum(u8) {
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
    pressed_play,
    pressed_pause,
    pressed_quit,
    pressed_replay,
    pressed_ignore,

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
    board_width: u16,
    board_height: u16,

    paddle_width: u16,
    paddle_height: u16,

    player1_x: u16,
    player1_y: u16,

    player2_x: u16,
    player2_y: u16,

    ball_radius: u16,
    ball_x: u16,
    ball_y: u16,
    player1_score: u8,
    player2_score: u8,
    player1_status: PlayerStatus,
    player2_status: PlayerStatus,
    timestamp: i64,
    _padding: u240,

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
            .player1_status = .unavailable,
            .player2_status = .unavailable,
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
