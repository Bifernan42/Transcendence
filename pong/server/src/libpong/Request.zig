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
const json = std.json;
const fmt = std.fmt;
const mem = std.mem;
const heap = std.heap;
const Buffer = std.ArrayListUnmanaged;
const Request = @This();

arena: heap.ArenaAllocator,
buffer: Buffer(u8),

pub fn init(allocator: mem.Allocator) Request {
    return .{
        .arena = heap.ArenaAllocator.init(allocator),
        .buffer = Buffer(u8).empty,
    };
}

pub fn deinit(self: *Request) void {
    self.arena.deinit();
    self.* = undefined;
}

pub fn isComplete(self: *Request) bool {
    const items = self.buffer.items[0..self.buffer.items.len];
    return std.mem.indexOf(u8, items, root.protocol.Delimiter) != null;
}

pub fn jsonSerialize(self: *Request, object: anytype) ![]const u8 {
    const allocator = self.arena.allocator();
    const items = try fmt.allocPrint(allocator, "{}" ++ root.protocol.Delimiter, .{object});
    try self.buffer.appendSlice(allocator, items);
    return items;
}

pub fn jsonDeserialize(self: *Request, comptime T: type, into: *T) !void {
    const allocator = self.arena.allocator();
    const slice = self.buffer.items;
    const delimiter = mem.indexOf(u8, slice, root.protocol.Delimiter);

    if (delimiter) |index| {
        const json_object = slice[0..index];
        into.* = try json.parseFromSliceLeaky(T, allocator, json_object, .{});
    }
}

fn internalSlice(self: *Request) []const u8 {
    return self.buffer.allocatedSlice()[0..self.buffer.items.len];
}
