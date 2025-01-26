// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Protocol.zig                                       :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/26 09:43:24 by pollivie          #+#    #+#             //
//   Updated: 2025/01/26 09:43:25 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const blt = @import("builtin");
const std = @import("std");
const json = std.json;
const Protocol = @This();

const DebugFmt: json.StringifyOptions = .{ .whitespace = .indent_4 };
pub const Delimiter: []const u8 = &[_]u8{0x1E};
pub const Formatting = if (blt.mode == .Debug) DebugFmt else .{};

pub const Host = enum(u4) { none, server, client };
pub const Message = enum(u4) { none, auth, update, failure, success, config };
pub const Status = enum(u8) { none, ok, err, later, confirm };

pub const Header = packed struct {
    host: Host = .none,
    tag: Message = .none,
    status: Status = .none,
    timestamp: i64 = 0,

    pub const init: Header = .{
        .host = .none,
        .tag = .none,
        .status = .none,
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
        try json.stringify(self, Formatting, writer);
    }
};

pub const Authentification = packed struct {
    pub const Request = struct {
        header: Header = .init,
        pass: []const u8 = "test",

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            try json.stringify(self, Formatting, writer);
        }
    };

    pub const Response = packed struct {
        header: Header = .init,
        token_id: u64 = 0xBAAAAAAB,

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            try json.stringify(self, Formatting, writer);
        }
    };

    pub const testing_request: Request = .{
        .header = .init,
        .pass = "test",
    };

    pub const testing_response: Response = .{
        .header = .init,
        .token_id = 0xBAAAAAAB,
    };
};

pub const Update = packed struct {};
