// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Protocol.zig                                       :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/19 15:12:13 by pollivie          #+#    #+#             //
//   Updated: 2025/01/19 15:12:25 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const builtin = @import("builtin");
const root = @import("root");
const std = @import("std");
const net = std.net;
const mem = std.mem;
const log = std.log;
const heap = std.heap;
const posix = std.posix;
const json = std.json;
const Pong = @import("Pong.zig");
const Protocol = @This();

const opts: json.StringifyOptions = switch (builtin.mode) {
    .Debug => .{ .whitespace = .indent_4 },
    else => .{},
};

pub const Delimiter: []const u8 = &.{0xfe};

pub const Handshake = struct {
    pub const Request = struct {
        client_id: []const u8 = "none",
        timestamp: i64 = 0,

        pub const default: Handshake.Request = .{
            .client_id = "none",
            .timestamp = 0,
        };

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            try json.stringify(self, opts, writer);
        }
    };

    pub const Response = struct {
        token: u64 = 0,
        status: bool = true,
        timestamp: i64 = 0,

        pub const default: Handshake.Response = .{
            .token = 0,
            .status = true,
            .timestamp = 0,
        };

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            try json.stringify(self, opts, writer);
        }
    };
};

pub const Config = struct {
    pub const Request = struct {
        token: u64 = 0,
        timestamp: i64 = 0,

        pub const default: Config.Request = .{
            .token = 0,
            .timestamp = 0,
        };

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            try json.stringify(self, opts, writer);
        }
    };

    pub const Response = struct {
        status: bool = true,
        state: Pong.GameState = Pong.GameState.default,
        timestamp: i64 = 0,

        pub const default: Config.Response = .{
            .status = true,
            .state = Pong.GameState.default,
            .timestamp = 0,
        };

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            try json.stringify(self, opts, writer);
        }
    };
};

pub const Update = struct {
    pub const Request = struct {
        event: Pong.Player.Event = Pong.Player.Event.default,
        timestamp: i64 = 0,

        pub const default: Update.Request = .{
            .event = Pong.Player.Event.default,
            .timestamp = 0,
        };

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            try json.stringify(self, opts, writer);
        }
    };

    pub const Response = struct {
        state: Pong.GameState = Pong.GameState.default,
        timestamp: i64 = 0,

        pub const default: Update.Response = .{
            .state = Pong.GameState.default,
            .timestamp = 0,
        };

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            try json.stringify(self, opts, writer);
        }
    };
};
