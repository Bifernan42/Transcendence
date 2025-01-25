// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Buffer.zig                                         :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/25 10:37:00 by pollivie          #+#    #+#             //
//   Updated: 2025/01/25 10:37:01 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const math = std.math;
const heap = std.heap;
const Allocator = mem.Allocator;
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const assert = std.debug.assert;

/// convenient wrapper around the ArrayListUnmanaged, wrapping building block Functions
pub fn Buffer(comptime T: type) type {
    return struct {
        pub const Self = T;
        list: ArrayListUnmanaged(T),
        allocator: mem.Allocator,

        const empty: []T = &.{};

        pub fn init(allocator: mem.Allocator) Self {
            return .{
                .list = ArrayListUnmanaged(T).init(allocator),
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            self.list.deinit(self.allocator);
        }

        pub fn pushSliceFront(self: *Self, items: []const T) !void {
            try self.list.insertSlice(self.allocator, 0, items);
        }

        pub fn pushSliceBack(self: *Self, items: []const T) !void {
            try self.list.appendSlice(self.allocator, items);
        }

        pub fn pushSliceAt(self: *Self, index: usize, items: []const T) !void {
            try self.list.insertSlice(self.allocator, index, items);
        }

        pub fn popSliceFront(self: *Self, length: usize) !?[]T {
            if (self.list.items.len < length) return null;
            const result = try self.allocator.alloc(T, length);
            @memcpy(result, self.list.items[0..length]);
            try self.list.replaceRange(self.allocator, 0, length, empty);
            return result;
        }

        pub fn popSliceBack(self: *Self, length: usize) !?[]T {
            if (self.list.items.len < length) return null;
            const result = try self.allocator.alloc(T, length);
            const list_len = self.list.len;
            @memcpy(result, self.list.items[list_len -| length..]);
            try self.list.replaceRange(self.allocator, list_len -| length, length, empty);
            return result;
        }

        pub fn popSliceAt(self: *Self, index: usize, length: usize) !?[]T {
            if (self.list.items.len < (index + length)) return null;
            const result = try self.allocator.alloc(T, length);
            @memcpy(result, self.list.items[index .. index + length]);
            try self.list.replaceRange(self.allocator, index, length, empty);
            return result;
        }

        pub fn pushFront(self: *Self, item: T) !void {
            try self.list.insert(self.allocator, 0, item);
        }

        pub fn pushBack(self: *Self, item: T) !void {
            try self.list.append(self.allocator, item);
        }

        pub fn pushAt(self: *Self, index: usize, item: T) !void {
            try self.list.insert(self.allocator, index, item);
        }

        pub fn popFront(self: *Self) ?T {
            if (self.list.len == 0) return null;
            return self.list.orderedRemove(0);
        }

        pub fn popBack(self: *Self) ?T {
            return self.list.popOrNull();
        }

        pub fn popAt(self: *Self, index: usize) !?T {
            if (self.list.len == 0 or self.list.len < index) return null;
            return self.list.orderedRemove(index);
        }

        pub fn allocatedSlice(self: *const Self) []T {
            return self.list.allocatedSlice();
        }

        pub fn slice(self: *const Self) []const T {
            return self.list.items[0..self.len()];
        }

        pub fn len(self: *const Self) usize {
            return self.list.items.len;
        }

        pub fn capacity(self: *const Self) usize {
            return self.list.capacity;
        }

        pub fn reset(self: *Self) void {
            self.list.clearAndFree(self.allocator);
        }
    };
}
