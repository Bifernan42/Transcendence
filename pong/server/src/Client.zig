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
const String = @import("String.zig").String;

const Client = @This();

gpa: mem.Allocator,
address: net.Address,
socket: posix.socket_t,
buffer: String,
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
        .buffer = String.init(gpa),
        .status = .connected,
    };
}

pub fn deinit(client: *Client) void {
    client.buffer.deinit();
}

pub fn getPollIn(client: *const Client) posix.pollfd {
    return .{
        .fd = client.socket,
        .events = posix.POLL.IN,
        .revents = 0,
    };
}

pub fn readUntilMessage(client: *Client, allocator: mem.Allocator) !?[]u8 {
    var temp_buffer: [1024]u8 = undefined;
    const buffer = &client.buffer;
    while (true) {
        if (!buffer.isEmpty() and buffer.containsScalar(Protocol.Delimiter[0])) {
            return buffer.extractUntilDelimiterAlloc(allocator, Protocol.Delimiter[0]);
        }
        const bytes_read = try posix.recv(client.socket, &temp_buffer, 0);

        if (bytes_read == 0) {
            return error.Closed;
        }

        try buffer.insertSliceBack(temp_buffer[0..bytes_read]);
    }
}

pub fn getMessage(client: *Client, allocator: mem.Allocator) !?[]u8 {
    return try client.readUntilMessage(allocator);
}
