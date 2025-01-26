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

pub const Delimiter: []const u8 = &[_]u8{0x1E};

pub const Host = enum {
    none,
    server,
    client,
};

pub const Status = enum {
    none,
    ok,
    err,
};

pub const MessageKind = enum {
    empt,
    auth,
    conn,
    dcon,
    wait,
    play,
    done,
    ping,
    pong,
};

pub const Header = struct {
    host: Host = .none,
    tag: MessageKind,
    status: Status = .none,
    timestamp: i64 = 0,

    pub const empty: Header = .{
        .host = .none,
        .tag = .empt,
        .status = .ok,
        .timestamp = 0,
    };

    pub const auth: Header = .{
        .host = .none,
        .tag = .auth,
        .status = .ok,
        .timestamp = 0,
    };
    pub const conn: Header = .{
        .host = .none,
        .tag = .conn,
        .status = .ok,
        .timestamp = 0,
    };

    pub const dcon: Header = .{
        .host = .none,
        .tag = .dcon,
        .status = .ok,
        .timestamp = 0,
    };
    pub const wait: Header = .{
        .host = .none,
        .tag = .wait,
        .status = .ok,
        .timestamp = 0,
    };

    pub const play: Header = .{
        .host = .none,
        .tag = .play,
        .status = .ok,
        .timestamp = 0,
    };

    pub const done: Header = .{
        .host = .none,
        .tag = .done,
        .status = .ok,
        .timestamp = 0,
    };
    pub const ping: Header = .{
        .host = .none,
        .tag = .ping,
        .status = .ok,
        .timestamp = 0,
    };

    pub const pong: Header = .{
        .host = .none,
        .tag = .pong,
        .status = .ok,
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
        try json.stringify(self, .{}, writer);
    }
};

pub const Empty = struct {
    pub const Request = struct {
        head: Header = .empty,

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            try json.stringify(self, .{}, writer);
        }
    };

    pub const Response = struct {
        head: Header = .empty,

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            try json.stringify(self, .{}, writer);
        }
    };
};

pub const Auth = struct {
    pub const Request = struct {
        head: Header = .auth,
        role: []const u8 = "",
        name: []const u8 = "",
        pass: []const u8 = "",

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            try json.stringify(self, .{}, writer);
        }
    };

    pub const Response = struct {
        head: Header = .auth,
        token: u64 = 0,

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            try json.stringify(self, .{}, writer);
        }
    };
};

pub const Conn = struct {
    pub const Request = struct {
        head: Header = .conn,

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            try json.stringify(self, .{}, writer);
        }
    };

    pub const Response = struct {
        head: Header = .conn,

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            try json.stringify(self, .{}, writer);
        }
    };
};

pub const Dcon = struct {
    pub const Request = struct {
        head: Header = .dcon,

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            try json.stringify(self, .{}, writer);
        }
    };

    pub const Response = struct {
        head: Header = .dcon,

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            try json.stringify(self, .{}, writer);
        }
    };
};

pub const Wait = struct {
    pub const Request = struct {
        head: Header = .wait,

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            try json.stringify(self, .{}, writer);
        }
    };

    pub const Response = struct {
        head: Header = .wait,

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            try json.stringify(self, .{}, writer);
        }
    };
};

pub const Play = struct {
    pub const Request = struct {
        head: Header = .play,

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            try json.stringify(self, .{}, writer);
        }
    };

    pub const Response = struct {
        head: Header = .play,

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            try json.stringify(self, .{}, writer);
        }
    };
};

pub const Done = struct {
    pub const Request = struct {
        head: Header = .done,

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            try json.stringify(self, .{}, writer);
        }
    };

    pub const Response = struct {
        head: Header = .done,

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            try json.stringify(self, .{}, writer);
        }
    };
};

pub const ClientInfo = struct {
    name: []const u8 = "P1",
    role: []const u8 = "player1",
    pass: []const u8 = "pass",
    tokn: u64 = 1,
    last_req: Status = .none,
    last_res: Status = .none,
    last_req_time: i64 = 0,
    last_res_time: i64 = 0,
    last_req_head: Header = .empty,
    last_res_head: Header = .empty,
    last_state: State = .connected,
    curr_state: State = .connected,

    pub const State = enum {
        connected,
        disconnnected,
        authentificated,
        waiting,
        playing,
        done,
    };
};
