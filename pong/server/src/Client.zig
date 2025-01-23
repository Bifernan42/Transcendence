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
const MessageBuffer = @import("MessageBuffer.zig");

const Client = @This();

arena: heap.ArenaAllocator,
address: net.Address,
socket: posix.socket_t,
buffer: MessageBuffer,

pub fn init(gpa: mem.Allocator, address: net.Address, socket: posix.socket_t) !Client {
    var arena: heap.ArenaAllocator = .init(gpa);
    errdefer arena.deinit();
    return .{
        .arena = arena,
        .address = address,
        .socket = socket,
        .buffer = try MessageBuffer.initCapacity(arena.allocator(), mem.page_size, Protocol.Delimiter[0]),
    };
}

pub fn deinit(client: *Client) void {
    client.arena.deinit();
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
        if (try buffer.extractNextMessage(allocator)) |message| {
            return message;
        }

        const bytes_read = try posix.recv(client.socket, &temp_buffer, 0);

        if (bytes_read == 0) {
            return error.Closed;
        }

        try buffer.append(temp_buffer[0..bytes_read]);
    }
}

pub fn getMessage(client: *Client, allocator: mem.Allocator) !?[]u8 {
    if (try client.buffer.extractNextMessage(allocator)) |message| {
        return message;
    } else {
        return try client.readUntilMessage(allocator);
    }
}
