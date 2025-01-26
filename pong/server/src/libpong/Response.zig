// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Response.zig                                       :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/26 15:25:38 by pollivie          #+#    #+#             //
//   Updated: 2025/01/26 15:25:39 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const root = @import("root.zig");
const Delimiter = root.protocol.Delimiter;
const json = std.json;
const fmt = std.fmt;
const mem = std.mem;
const heap = std.heap;
const posix = std.posix;
const Buffer = std.ArrayListUnmanaged;

pub const Response = struct {
    arena: heap.ArenaAllocator,
    buffer: Buffer(u8),

    pub fn init(allocator: mem.Allocator) Response {
        return .{
            .arena = heap.ArenaAllocator.init(allocator),
            .buffer = Buffer(u8).empty,
        };
    }

    pub fn deinit(self: *Response) void {
        self.arena.deinit();
        self.* = undefined;
    }

    pub fn isComplete(self: *Response) bool {
        const items = self.buffer.items[0..self.buffer.items.len];
        return std.mem.indexOf(u8, items, Delimiter) != null;
    }

    pub fn jsonSerialize(self: *Response, object: anytype) !void {
        const allocator = self.arena.allocator();
        const items = try fmt.allocPrint(allocator, "{}" ++ Delimiter, .{object});
        try self.buffer.appendSlice(allocator, items);
    }

    pub fn serialized(self: *Response) ?[]const u8 {
        if (mem.indexOf(u8, self.internalSlice(), Delimiter)) |found| {
            return self.internalSlice()[0..found];
        } else {
            return null;
        }
    }

    pub fn jsonDeserialize(self: *Response, comptime T: type, into: *T) !void {
        const allocator = self.arena.allocator();
        const slice = self.buffer.items;
        const delimiter = mem.indexOf(u8, slice, Delimiter);

        if (delimiter) |index| {
            const json_object = slice[0..index];
            into.* = try json.parseFromSliceLeaky(T, allocator, json_object, .{});
        }
    }

    fn internalSlice(self: *Response) []const u8 {
        return self.buffer.allocatedSlice()[0..self.buffer.items.len];
    }
};
