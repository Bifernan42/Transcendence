const std = @import("std");
const net = std.net;
const log = std.log;
const mem = std.mem;
const json = std.json;
const heap = std.heap;
const time = std.time;
const posix = std.posix;
const math = std.math;
const process = std.process;
const io = std.io;
const debug = std.debug;
const builtin = @import("builtin");
const Allocator = mem.Allocator;
const assert = debug.assert;
const MessageBuffer = @This();

allocator: Allocator = undefined,
items: []u8 = &[_]u8{},
capacity: usize = 0,
windex: usize = 0,
rindex: usize = 0,
delimiter: u8 = 0,

pub fn init(allocator: Allocator, delimiter: u8) MessageBuffer {
    return .{
        .allocator = allocator,
        .delimiter = delimiter,
        .capacity = 0,
        .windex = 0,
        .rindex = 0,
        .items = &[_]u8{},
    };
}

pub fn initCapacity(allocator: Allocator, num: usize, delimiter: u8) Allocator.Error!MessageBuffer {
    var self = MessageBuffer.init(allocator, delimiter);
    try self.ensureTotalCapacityPrecise(num);
    return self;
}

pub fn deinit(self: *MessageBuffer) void {
    self.allocator.free(self.allocatedSlice());
}

pub fn allocatedSlice(self: *const MessageBuffer) []u8 {
    return self.items.ptr[0..self.capacity];
}

pub fn resize(self: *MessageBuffer, new_len: usize) Allocator.Error!void {
    try self.ensureTotalCapacity(new_len);
    self.items.len = new_len;
}

pub fn ensureTotalCapacity(self: *MessageBuffer, new_capacity: usize) Allocator.Error!void {
    if (self.capacity >= new_capacity) return;

    const better_capacity = growCapacity(self.capacity, new_capacity);
    return self.ensureTotalCapacityPrecise(better_capacity);
}

pub fn clearRetainingCapacity(self: *MessageBuffer) void {
    self.items.len = 0;
    self.windex = 0;
    self.rindex = 0;
}

pub fn clearAndFree(self: *MessageBuffer) void {
    self.allocator.free(self.allocatedSlice());
    self.items.len = 0;
    self.capacity = 0;
    self.windex = 0;
    self.rindex = 0;
}

pub fn ensureTotalCapacityPrecise(self: *MessageBuffer, new_capacity: usize) Allocator.Error!void {
    std.debug.print("Buffer capacity: {d}, windex: {d}, capacity {d},new_capacity: {d}\n", .{ self.capacity, self.windex, self.capacity, new_capacity });

    if (self.capacity >= new_capacity) {
        return;
    }

    const old_memory = self.allocatedSlice();
    if (self.allocator.resize(old_memory, new_capacity)) {
        self.capacity = new_capacity;
    } else {
        const new_memory = try self.allocator.alloc(u8, new_capacity);
        @memcpy(new_memory[0..self.items.len], self.items);
        self.allocator.free(old_memory);
        self.items.ptr = new_memory.ptr;
        self.items.len = new_memory.len;
        self.capacity = new_memory.len;
    }
    std.debug.print("Buffer capacity: {d}, windex: {d}, capacity {d},new_capacity: {d}\n", .{ self.capacity, self.windex, self.capacity, new_capacity });
}

fn growCapacity(current: usize, minimum: usize) usize {
    var new = current;
    while (true) {
        new +|= new / 2 + 8;
        if (new >= minimum)
            return new;
    }
}

pub fn append(self: *MessageBuffer, data: []const u8) !void {
    const space_needed = data.len;
    try self.ensureTotalCapacity(self.windex + space_needed);
    try self.resize(self.windex + space_needed);
    @memcpy(self.items[self.windex .. self.windex + space_needed], data);
    self.windex += space_needed;
}

pub fn extractNextMessage(self: *MessageBuffer, allocator: Allocator) Allocator.Error!?[]u8 {
    if (self.rindex >= self.windex) {
        return null;
    }

    var delimiter_index = self.rindex;
    while (delimiter_index < self.windex and self.items[delimiter_index] != self.delimiter) {
        delimiter_index += 1;
    }

    if (delimiter_index == self.windex) {
        return null;
    }

    const message_len = delimiter_index - self.rindex + 1;
    const message = try allocator.alloc(u8, message_len);
    @memcpy(message, self.items[self.rindex .. self.rindex + message_len]);
    self.rindex += message_len;
    if (self.rindex >= @mod(self.capacity, 2)) {
        self.compact();
    }
    return message[0 .. message_len - 1];
}

pub fn compact(self: *MessageBuffer) void {
    std.debug.print("before compact : {s}\n", .{self.items[self.rindex..self.windex]});
    if (self.rindex > 0) {
        const remaining = (self.windex -| self.rindex);
        mem.copyForwards(u8, self.items[0..remaining], self.items[self.rindex..self.windex]);
        self.rindex = 0;
        self.windex = remaining;
        std.debug.print("after compact : {s}\n", .{self.items[0..remaining]});
    }
}
