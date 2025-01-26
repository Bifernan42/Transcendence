// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Request.zig                                        :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/26 15:27:34 by pollivie          #+#    #+#             //
//   Updated: 2025/01/26 15:27:36 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const root = @import("root.zig");
const Delimiter = root.protocol.Delimiter;
const json = std.json;
const fmt = std.fmt;
const mem = std.mem;
const heap = std.heap;
const Buffer = std.ArrayListUnmanaged;
const Stream = @import("Stream.zig");
const Request = @This();

arena: heap.ArenaAllocator,
buffer: Buffer(u8),
stream: Stream,
last_req: ?[]const u8,

pub fn init(allocator: mem.Allocator) Request {
    return .{
        .arena = heap.ArenaAllocator.init(allocator),
        .buffer = Buffer(u8).empty,
        .stream = undefined,
        .last_req = null,
    };
}

pub fn deinit(self: *Request) void {
    self.arena.deinit();
    self.* = undefined;
}

pub fn attachStream(self: *Request, stream: Stream) void {
    self.stream = stream;
}

pub fn appendSlice(self: *Request, items: []const u8) !void {
    try self.buffer.appendSlice(self.arena.allocator(), items);
}

pub fn isComplete(self: *Request) bool {
    const items = self.buffer.items[0..self.buffer.items.len];
    return std.mem.indexOf(u8, items, Delimiter) != null;
}

pub fn jsonSerialize(self: *Request, object: anytype) ![]const u8 {
    const allocator = self.arena.allocator();
    const items = try fmt.allocPrint(allocator, "{}" ++ Delimiter, .{object});
    try self.buffer.appendSlice(allocator, items);
    self.last_req = items;
    return items;
}

pub fn serialized(self: *Request) ?[]const u8 {
    if (mem.indexOf(u8, self.internalSlice(), Delimiter)) |found| {
        return self.internalSlice()[0..found];
    } else {
        return null;
    }
}

pub fn jsonDeserialize(self: *Request, comptime T: type, into: *T) !void {
    const allocator = self.arena.allocator();
    const slice = self.buffer.items;
    const delimiter = mem.indexOf(u8, slice, Delimiter);

    if (delimiter) |index| {
        const json_object = slice[0..index];
        self.last_req = json_object;
        into.* = try json.parseFromSliceLeaky(T, allocator, json_object, .{});
    }
}

fn internalSlice(self: *Request) []const u8 {
    return self.buffer.allocatedSlice()[0..self.buffer.items.len];
}

fn internalLength(self: *Request) usize {
    return self.buffer.items.len;
}

fn getRemaining(self: *Request) []const u8 {
    const buff = self.internalSlice();
    const len = self.internalLength();
    if (self.last_req) |request| {
        if (request.len == len) return buff[0..0];
        return buff[request.len..];
    }
    return buff[0..self.internalLength()];
}

pub fn clearLastRetainRemaining(self: *Request) void {
    var temp: [1024]u8 = undefined;
    var len: usize = 0;

    if (self.last_req) |_| {
        const remaining = self.getRemaining();
        len = remaining.len;
        @memcpy(temp[0..len], remaining);
    }
    _ = self.arena.reset(.retain_capacity);
    self.buffer = Buffer(u8).initCapacity(self.arena.allocator(), len) catch unreachable;
    self.buffer.appendSlice(self.arena.allocator(), temp[0..len]) catch unreachable;
}
