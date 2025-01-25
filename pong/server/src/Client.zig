// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Client.zig                                         :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/22 21:28:18 by pollivie          #+#    #+#             //
//   Updated: 2025/01/22 21:28:19 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const net = std.net;
const log = std.log;
const mem = std.mem;
const json = std.json;
const heap = std.heap;
const time = std.time;
const posix = std.posix;
const process = std.process;
const io = std.io;
const builtin = @import("builtin");
const Protocol = @import("Protocol.zig");

const Client = @This();

gpa: mem.Allocator,
address: net.Address,
socket: posix.socket_t,
status: Status,

pub const Status = enum {
    connected,
    authentificated,
    disconnected,
    ready,
};

pub fn init(gpa: mem.Allocator, address: net.Address, socket: posix.socket_t) !Client {
    return .{
        .gpa = gpa,
        .address = address,
        .socket = socket,
        .status = .connected,
    };
}

pub fn deinit(_: *Client) void {
    // client.buffer.deinit();
}

pub fn getPollIn(client: *const Client) posix.pollfd {
    return .{
        .fd = client.socket,
        .events = posix.POLL.IN,
        .revents = 0,
    };
}
