// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   PongServer.zig                                     :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/28 12:59:13 by pollivie          #+#    #+#             //
//   Updated: 2025/01/28 12:59:13 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const lib = @import("libpong");
const net = std.net;
const posix = std.posix;
const mem = std.mem;
const heap = std.heap;
const RingBuffer = std.RingBuffer;

const PongServer = @This();

pub const Mode = enum {
    read,
    write,
    err,
};

gpa: mem.Allocator,
sock: posix.socket_t,
req: std.RingBuffer,
res: std.RingBuffer,
addr: net.Address,
mode: Mode,

pub fn init(gpa: mem.Allocator, addr: net.Address, sock: posix.socket_t) !PongServer {
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
        .mode = .write,
    };
}

pub fn deinit(self: *PongServer) void {
    if (self.sock != -1) {
        posix.close(self.sock);
    }
    self.req.deinit(self.gpa);
    self.res.deinit(self.gpa);
    self.* = undefined;
}

pub fn read(self: *PongServer) !void {
    var buffer: [lib.MessageTotalBytes]u8 = undefined;
    const rbytes = try posix.read(self.sock, buffer[0..]);
    if (rbytes != lib.MessageTotalBytes) {
        return error.partialRead;
    }
    self.req.writeSliceAssumeCapacity(buffer[0..]);
}

pub fn getRequest(self: *PongServer, out_message: *[]u8) bool {
    if (self.req.read_index < out_message.len) {
        return false;
    }
    self.req.readFirst(out_message.*, out_message.len) catch unreachable;
    return true;
}

pub fn putResponse(self: *PongServer, response: *[]u8) bool {
    if (response.len != lib.MessageTotalBytes) {
        return false;
    }
    self.res.writeSliceAssumeCapacity(response.*);
    return true;
}

pub fn write(self: *PongServer) !void {
    var buffer: [lib.MessageTotalBytes]u8 = undefined;
    try self.res.readLast(buffer[0..], lib.MessageTotalBytes);
    const wbytes = try posix.write(self.sock, buffer[0..]);

    if (wbytes != lib.MessageTotalBytes) {
        return error.partialWrite;
    }
}
