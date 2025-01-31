// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Client.zig                                         :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/27 21:08:10 by pollivie          #+#    #+#             //
//   Updated: 2025/01/27 21:08:11 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const lib = @import("libpong");
const process = std.process;
const heap = std.heap;
const mem = std.mem;
const net = std.net;
const cli = lib.cli;
const log = std.log;
const posix = std.posix;

const Client = @This();

pub const Mode = enum {
    recv,
    send,
    err,
};

gpa: mem.Allocator,
sock: posix.socket_t,
req: std.RingBuffer,
res: std.RingBuffer,
addr: net.Address,
mode: Mode,

pub fn init(gpa: mem.Allocator, addr: net.Address, sock: posix.socket_t) !Client {
    const total_capacity = lib.MessageTotalBytes * lib.MessageBufferCapacity;
    var response = try std.RingBuffer.init(gpa, total_capacity);
    errdefer response.deinit(gpa);
    var request = try std.RingBuffer.init(gpa, total_capacity);
    errdefer request.deinit(gpa);
    return .{
        .gpa = gpa,
        .addr = addr,
        .sock = sock,
        .res = response,
        .req = request,
        .mode = .recv,
    };
}

pub fn deinit(self: *Client) void {
    if (self.sock != -1) {
        posix.close(self.sock);
    }
    self.req.deinit(self.gpa);
    self.res.deinit(self.gpa);
    self.* = undefined;
}

pub fn recv(self: *Client) !void {
    var buffer: [lib.MessageTotalBytes]u8 = undefined;
    const rbytes = try posix.recv(self.sock, buffer[0..], 0);
    if (rbytes != lib.MessageTotalBytes) {
        return error.partialRead;
    }
    self.req.writeSliceAssumeCapacity(buffer[0..]);
}

pub fn getRequest(self: *Client, out_message: *[lib.MessageTotalBytes]u8) bool {
    if (self.req.read_index < out_message.len) {
        return false;
    }
    self.req.readFirst(out_message, out_message.len) catch unreachable;
    return true;
}

pub fn putResponse(self: *Client, response: []u8) bool {
    if (response.len != lib.MessageTotalBytes) {
        return false;
    }
    self.res.writeSliceAssumeCapacity(response[0..lib.MessageTotalBytes]);
    return true;
}

pub fn send(self: *Client) !void {
    var buffer: [lib.MessageTotalBytes]u8 = undefined;
    try self.res.readLast(buffer[0..], lib.MessageTotalBytes);
    const wbytes = try posix.send(self.sock, buffer[0..], 0);

    if (wbytes != lib.MessageTotalBytes) {
        return error.partialWrite;
    }
}
