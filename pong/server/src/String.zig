const std = @import("std");
const mem = std.mem;
const heap = std.heap;
const math = std.math;
const debug = std.debug;
const builtin = @import("builtin");
const Allocator = mem.Allocator;

pub const String = struct {
    allocator: Allocator,
    str: StringUnmanaged,

    pub const Error = StringUnmanaged.Error;

    pub fn init(allocator: Allocator) String {
        return .{
            .allocator = allocator,
            .str = StringUnmanaged.init(),
        };
    }

    pub fn initCapacity(allocator: Allocator, capacity: usize) !String {
        return .{
            .allocator = allocator,
            .str = try StringUnmanaged.initCapacity(allocator, capacity),
        };
    }

    pub fn initFromStr(allocator: Allocator, str: []const u8) !String {
        return .{
            .allocator = allocator,
            .str = try StringUnmanaged.initFromStr(allocator, str),
        };
    }

    pub fn deinit(self: *String) void {
        self.str.deinit(self.allocator);
    }

    pub fn clearRetainCapacity(self: *String) void {
        self.str.clearRetainCapacity();
    }

    pub fn clearAndFree(self: *String) void {
        self.str.clearAndFree(self.allocator);
    }

    pub fn reserve(self: *String, new_capacity: usize) !void {
        try self.str.reserve(self.allocator, new_capacity);
    }

    pub fn shrinkUnusedCapacity(self: *String) !void {
        try self.str.shrinkUnusedCapacity(self.allocator);
    }

    pub fn get(self: *String, index: usize) !*u8 {
        return try self.str.get(index);
    }

    pub fn set(self: *String, index: usize, item: u8) !void {
        try self.str.set(index, item);
    }

    pub fn eraseScalarFront(self: *String) !void {
        try self.str.eraseScalarFront();
    }

    pub fn eraseScalarBack(self: *String) !void {
        try self.str.eraseScalarBack();
    }

    pub fn eraseScalarAt(self: *String, at: usize) !void {
        try self.str.eraseScalarAt(at);
    }

    pub fn insertSliceFront(self: *String, slice: []const u8) !void {
        try self.str.insertSliceFront(self.allocator, slice);
    }

    pub fn insertSliceBack(self: *String, slice: []const u8) !void {
        try self.str.insertSliceBack(self.allocator, slice);
    }

    pub fn insertSliceAt(self: *String, index: usize, slice: []const u8) !void {
        try self.str.insertSliceAt(self.allocator, index, slice);
    }

    pub fn indexOfFirstScalar(self: *const String, item: u8) ?usize {
        return mem.indexOfScalar(u8, self.str.data(), item);
    }

    pub fn indexOfFirstScalarFrom(self: *const String, from: usize, item: u8) ?usize {
        return mem.indexOfScalar(u8, self.str.data()[from..], item);
    }

    pub fn indexOfLastScalar(self: *const String, item: u8) ?usize {
        return mem.lastIndexOfScalar(u8, self.str.data(), item);
    }

    pub fn indexOfLastScalarFrom(self: *const String, from: usize, item: u8) ?usize {
        return mem.lastIndexOfScalar(u8, self.str.data()[from..], item);
    }

    pub fn extractUntilDelimiterAlloc(self: *String, out_allocator: mem.Allocator, delimiter: u8) !?[]u8 {
        if (!self.str.containsScalar(delimiter)) {
            return null;
        }
        const buffer = self.str.data();
        const index_of_delimiter = self.str.indexOfFirstScalar(delimiter) orelse return null;
        const result = try out_allocator.dupe(u8, buffer[0..index_of_delimiter]);
        try self.str.eraseRangeFront(result.len);
        return result;
    }

    pub fn isEmpty(self: *String) bool {
        return self.str.isEmpty();
    }

    pub fn isFull(self: *String) bool {
        return self.str.isFull();
    }

    pub fn startsWithScalar(self: *String, item: u8) bool {
        return self.str.startsWithScalar(item);
    }

    pub fn endsWithScalar(self: *String, item: u8) bool {
        return self.str.endsWithScalar(item);
    }

    pub fn containsScalar(self: *String, item: u8) bool {
        return self.str.containsScalar(item);
    }

    pub fn countScalar(self: *String, item: u8) usize {
        return self.str.countScalar(item);
    }

    pub fn data(self: *String) []u8 {
        return self.str.data();
    }

    pub fn allocatedSlice(self: *String) []u8 {
        return self.str.allocatedSlice();
    }

    pub fn eraseRangeFront(self: *String, count: usize) !void {
        try self.str.eraseRangeFront(count);
    }

    pub fn eraseRangeBack(self: *String, count: usize) !void {
        try self.str.eraseRangeBack(count);
    }

    pub fn eraseRangeAt(self: *String, at: usize, count: usize) !void {
        try self.str.eraseRangeAt(at, count);
    }
};

pub const StringUnmanaged = struct {
    ptr: [*]u8 = undefined,
    len: usize = 0,
    cap: usize = 0,

    pub const Error = error{
        Empty,
        Full,
        IndexOutOfRange,
    } || Allocator.Error;

    pub fn init() StringUnmanaged {
        return .{
            .ptr = &[_]u8{},
            .len = 0,
            .cap = 0,
        };
    }

    pub fn initCapacity(allocator: Allocator, capacity: usize) StringUnmanaged.Error!StringUnmanaged {
        var self = init();
        try self.reserve(allocator, capacity);
        return self;
    }

    pub fn initFromStr(allocator: Allocator, str: []const u8) StringUnmanaged.Error!StringUnmanaged {
        var self = try initCapacity(allocator, str.len);
        try self.insertSliceFront(allocator, str);
        return self;
    }

    pub fn deinit(self: *StringUnmanaged, allocator: Allocator) void {
        allocator.free(self.allocatedSlice());
        self.* = .init();
    }

    pub fn create(allocator: Allocator) StringUnmanaged.Error!*StringUnmanaged {
        const self = try allocator.create(StringUnmanaged);
        self.* = .init();
        return self;
    }

    pub fn destroy(self: *StringUnmanaged, allocator: Allocator) void {
        self.deinit(allocator);
        allocator.destroy(self);
    }

    pub fn clearRetainCapacity(self: *StringUnmanaged) void {
        self.len = 0;
    }

    pub fn clearAndFree(self: *StringUnmanaged, allocator: Allocator) void {
        self.deinit(allocator);
    }

    pub fn reserve(self: *StringUnmanaged, allocator: Allocator, new_capacity: usize) StringUnmanaged.Error!void {
        if (self.cap >= new_capacity) return;

        const better_capacity = growCapacity(self.cap, new_capacity);
        try self.reallocate(allocator, better_capacity);
    }

    pub fn shrinkUnusedCapacity(self: *StringUnmanaged, allocator: Allocator) StringUnmanaged.Error!void {
        if (self.cap == self.len) return;

        if (self.len == 0) {
            self.clearAndFree(allocator);
        } else {
            try self.reallocate(allocator, self.len);
        }
    }

    fn reallocate(self: *StringUnmanaged, allocator: Allocator, new_capacity: usize) StringUnmanaged.Error!void {
        if (self.isEmpty() and self.cap == 0) {
            const new_ptr = try allocator.alloc(u8, new_capacity);
            self.ptr = new_ptr.ptr;
            self.cap = new_capacity;
            self.updateLenAfterResize();
        } else {
            const new_ptr = try allocator.realloc(self.allocatedSlice(), new_capacity);
            self.ptr = new_ptr.ptr;
            self.cap = new_capacity;
            self.updateLenAfterResize();
        }
    }

    pub fn get(self: *StringUnmanaged, index: usize) StringUnmanaged.Error!*u8 {
        return self.getAt(index);
    }

    pub fn set(self: *StringUnmanaged, index: usize, item: u8) StringUnmanaged.Error!void {
        try self.setAt(index, item);
    }

    pub fn eraseScalarFront(self: *StringUnmanaged) !void {
        try self.eraseScalar(0);
    }

    pub fn eraseScalarBack(self: *StringUnmanaged) !void {
        try self.eraseScalar(self.len -| 1);
    }

    pub fn eraseScalarAt(self: *StringUnmanaged, at: usize) !void {
        try self.eraseScalar(at);
    }

    pub fn insertSliceFront(self: *StringUnmanaged, allocator: Allocator, slice: []const u8) !void {
        try self.insertSliceRange(allocator, 0, slice);
    }

    pub fn insertSliceBack(self: *StringUnmanaged, allocator: Allocator, slice: []const u8) !void {
        try self.insertSliceRange(allocator, self.len, slice);
    }

    pub fn insertSliceAt(self: *StringUnmanaged, allocator: Allocator, index: usize, slice: []const u8) !void {
        try self.insertSliceRange(allocator, index, slice);
    }

    pub fn isEmpty(self: *const StringUnmanaged) bool {
        return self.len == 0;
    }

    pub fn isFull(self: *const StringUnmanaged) bool {
        return self.len == self.cap;
    }

    pub fn startsWithScalar(self: *const StringUnmanaged, item: u8) bool {
        return mem.startsWith(u8, self.data(), &.{item});
    }

    pub fn endsWithScalar(self: *const StringUnmanaged, item: u8) bool {
        return mem.endsWith(u8, self.data(), &.{item});
    }

    pub fn containsScalar(self: *const StringUnmanaged, item: u8) bool {
        return mem.containsAtLeast(u8, self.data(), 1, &.{item});
    }

    pub fn indexOfFirstScalar(self: *const StringUnmanaged, item: u8) ?usize {
        return mem.indexOfScalar(u8, self.data(), item);
    }

    pub fn indexOfFirstScalarFrom(self: *const StringUnmanaged, from: usize, item: u8) ?usize {
        return mem.indexOfScalar(u8, self.data()[from..], item);
    }

    pub fn indexOfLastScalar(self: *const StringUnmanaged, item: u8) ?usize {
        return mem.lastIndexOfScalar(u8, self.data(), item);
    }

    pub fn indexOfLastScalarFrom(self: *const StringUnmanaged, from: usize, item: u8) ?usize {
        return mem.lastIndexOfScalar(u8, self.data()[from..], item);
    }

    pub fn extractUntilDelimiterAlloc(self: *StringUnmanaged, out_allocator: mem.Allocator, delimiter: u8) ?[]u8 {
        if (!self.containsScalar(delimiter)) {
            return null;
        }
        const buffer = self.data();
        const index_of_delimiter = self.indexOfFirstScalar(delimiter) orelse return null;
        const result = try out_allocator.dupe(u8, buffer[0..index_of_delimiter]);
        self.eraseRangeFront(result.len);
        return result;
    }

    pub fn countScalar(self: *const StringUnmanaged, item: u8) usize {
        return mem.count(u8, self.allocatedSlice(), &.{item});
    }

    pub fn data(self: *const StringUnmanaged) []u8 {
        return self.ptr[0..self.len];
    }

    pub fn allocatedSlice(self: *const StringUnmanaged) []u8 {
        return self.ptr[0..self.cap];
    }

    fn validateRange(self: *const StringUnmanaged, from: usize, to: usize) StringUnmanaged.Error!void {
        if (from > to or to > self.len) {
            return StringUnmanaged.Error.IndexOutOfRange;
        }
    }

    fn validateIndex(self: *const StringUnmanaged, at: usize) StringUnmanaged.Error!void {
        return if (at >= self.len) Error.IndexOutOfRange;
    }

    fn updateLenAfterResize(self: *StringUnmanaged) void {
        if (self.len > self.cap) {
            self.len = self.cap;
        }
    }

    pub fn eraseRangeFront(self: *StringUnmanaged, count: usize) StringUnmanaged.Error!void {
        if (count == 0) return;
        try self.eraseRange(0, count);
    }

    pub fn eraseRangeBack(self: *StringUnmanaged, count: usize) StringUnmanaged.Error!void {
        if (count == 0) return;
        const from = self.len -| count;
        try self.validateRange(from, self.len);
        try self.eraseRange(from, self.len);
    }

    pub fn eraseRangeAt(self: *StringUnmanaged, at: usize, count: usize) StringUnmanaged.Error!void {
        if (count == 0) return;
        const to = at + count;
        try self.validateRange(at, to);
        try self.eraseRange(at, to);
    }

    fn eraseRange(self: *StringUnmanaged, from: usize, to: usize) StringUnmanaged.Error!void {
        if (from == to) return;

        try self.validateRange(from, to);

        const range_len = to - from;
        const old_len = self.len;
        const new_len = old_len - range_len;

        if (to < old_len) {
            const src = self.ptr + to;
            const dest = self.ptr + from;
            const remaining = old_len - to;
            mem.copyForwards(u8, dest[0..remaining], src[0..remaining]);
        }

        self.len = new_len;
    }

    fn insertSliceRange(self: *StringUnmanaged, allocator: Allocator, at: usize, slice: []const u8) StringUnmanaged.Error!void {
        const insert_len = slice.len;
        if (insert_len == 0) {
            return;
        }

        const new_len = self.len + insert_len;
        if (new_len > self.cap) {
            try self.reserve(allocator, new_len);
        }

        if (at < self.len) {
            const dest = self.ptr + at + insert_len;
            const src = self.ptr + at;
            const move_len = self.len - at;
            mem.copyBackwards(u8, dest[0..move_len], src[0..move_len]);
        }

        const dest = self.ptr + at;
        @memcpy(dest[0..insert_len], slice);
        self.len = new_len;
    }

    fn eraseScalar(self: *StringUnmanaged, at: usize) StringUnmanaged.Error!void {
        try self.eraseRangeAt(at, 1);
    }

    fn insertScalar(self: *StringUnmanaged, allocator: Allocator, at: usize, item: u8) StringUnmanaged.Error!void {
        const new_len = self.len + 1;
        if (new_len > self.cap) {
            try self.reserve(allocator, new_len);
        }

        if (at < self.len) {
            const dest = self.ptr + at + 1;
            const src = self.ptr + at;
            const move_len = self.len - at;
            mem.copyBackwards(u8, dest[0..move_len], src[0..move_len]);
        }
        const dest = self.ptr + at;
        dest[0] = item;
        self.len = new_len;
    }

    fn setAt(self: *StringUnmanaged, at: usize, item: u8) StringUnmanaged.Error!void {
        const ptr = try self.getAt(at);
        ptr.* = item;
    }

    fn getAt(self: *StringUnmanaged, at: usize) StringUnmanaged.Error!*u8 {
        try self.validateIndex(at);
        return &self.ptr[at];
    }
};

fn growCapacity(current: usize, minimum: usize) usize {
    var new = if (current == 0) 8 else current;
    while (new < minimum) {
        new += new / 2 + 8;
    }
    return new;
}

const testing = std.testing;
const expect = std.testing.expect;
const expectEqlStr = std.testing.expectEqualSlices;

const alloc = testing.allocator;

test "init" {
    var str = StringUnmanaged.init();
    defer str.deinit(alloc);
    try expect(str.len == 0);
    try expect(str.cap == 0);
    try expect(str.data().len == 0);
    try expect(str.allocatedSlice().len == 0);
}

test "initCapacity" {
    var str = try StringUnmanaged.initCapacity(alloc, 0);
    defer str.deinit(alloc);
    try expect(str.len == 0);
    try expect(str.cap == 0);
    try expect(str.data().len == 0);
    try expect(str.allocatedSlice().len == 0);
}

test "initCapacity10" {
    var str = try StringUnmanaged.initCapacity(alloc, 10);
    defer str.deinit(alloc);
    try expect(str.len == 0);
    try expect(str.cap >= 10);
    try expect(str.data().len == 0);
    try expect(str.allocatedSlice().len >= 10);
}

test "create" {
    var str = try StringUnmanaged.create(alloc);
    defer str.destroy(alloc);
    try expect(str.len == 0);
    try expect(str.cap == 0);
    try expect(str.data().len == 0);
    try expect(str.allocatedSlice().len == 0);
}

test "insertFront" {
    var str = try StringUnmanaged.initCapacity(alloc, 10);
    defer str.deinit(alloc);

    try str.insertSliceFront(alloc, "a");
    try expectEqlStr(u8, "a", str.data());

    try str.insertSliceFront(alloc, "b");
    try expectEqlStr(u8, "ba", str.data());
    try str.insertSliceFront(alloc, "cdefghij");
    try expectEqlStr(u8, "cdefghijba", str.data());
    try str.insertSliceFront(alloc, "");
    try expectEqlStr(u8, "cdefghijba", str.data());
}

test "insertBack" {
    var str = try StringUnmanaged.initCapacity(alloc, 10);
    defer str.deinit(alloc);

    try str.insertSliceBack(alloc, "a");
    try expectEqlStr(u8, "a", str.data());

    try str.insertSliceBack(alloc, "b");
    try expectEqlStr(u8, "ab", str.data());
    try str.insertSliceBack(alloc, "cdefghij");
    try expectEqlStr(u8, "abcdefghij", str.data());
    try str.insertSliceBack(alloc, "");
    try expectEqlStr(u8, "abcdefghij", str.data());
}

test "insertAt" {
    var str = try StringUnmanaged.initCapacity(alloc, 10);
    defer str.deinit(alloc);

    try str.insertSliceAt(alloc, 0, "a");
    try expectEqlStr(u8, "a", str.data());
    try str.insertSliceAt(alloc, 0, "b");
    try expectEqlStr(u8, "ba", str.data());
    try str.insertSliceAt(alloc, 2, "c");
    try expectEqlStr(u8, "bac", str.data());
}

test "insertAtLong" {
    var str = try StringUnmanaged.initCapacity(alloc, 10);
    defer str.deinit(alloc);

    try str.insertSliceAt(alloc, 0, "aaa_aaa_a_a_aaa_aaa");
    try expectEqlStr(u8, "aaa_aaa_a_a_aaa_aaa", str.data());

    try str.insertSliceAt(alloc, 9, "_b");
    try expectEqlStr(u8, "aaa_aaa_a_b_a_aaa_aaa", str.data());

    try str.insertSliceAt(alloc, str.len, "c");
    try expectEqlStr(u8, "aaa_aaa_a_b_a_aaa_aaac", str.data());
}

test "clearRetainCapacity" {
    var str = try StringUnmanaged.initCapacity(alloc, 10);
    defer str.deinit(alloc);
    str.clearRetainCapacity();
    try expect(str.len == 0);
    try expect(str.cap >= 0);
    try expect(str.data().len == 0);
    try expect(str.allocatedSlice().len >= 0);
}

test "clearAndFree" {
    var str = try StringUnmanaged.initCapacity(alloc, 10);
    defer str.deinit(alloc);
    str.clearAndFree(alloc);
    try expect(str.len == 0);
    try expect(str.cap >= 0);
    try expect(str.data().len == 0);
    try expect(str.allocatedSlice().len >= 0);
}

test "shrinkUnusedCapacity" {
    var str = try StringUnmanaged.initFromStr(alloc, "aaa_bbb_ccc");
    defer str.deinit(alloc);
    try str.shrinkUnusedCapacity(alloc);
    try expect(str.len == 11);
    try expect(str.cap == 11);
    try expect(str.data().len == 11);
    try expect(str.allocatedSlice().len == 11);
}

test "initFromStr" {
    {
        var str = try StringUnmanaged.initFromStr(alloc, "");
        defer str.deinit(alloc);
        try expect(str.len == 0);
        try expect(str.cap >= 0);
        try expect(str.data().len == 0);
        try expect(str.allocatedSlice().len >= 0);
    }

    {
        var str = try StringUnmanaged.initFromStr(alloc, "a");
        defer str.deinit(alloc);
        try expect(str.len == 1);
        try expect(str.cap >= 1);
        try expect(str.data().len == 1);
        try expect(str.allocatedSlice().len >= 1);
    }
}

test "eraseRangeFront" {
    var str = try StringUnmanaged.initFromStr(alloc, "aaa_bbb_ccc");
    defer str.deinit(alloc);

    try str.eraseRangeFront(3);
    try expectEqlStr(u8, "_bbb_ccc", str.data());
    try str.eraseRangeFront(0);
    try expectEqlStr(u8, "_bbb_ccc", str.data());
    try str.eraseRangeFront(str.data().len);
    try expectEqlStr(u8, "", str.data());
    try testing.expectError(StringUnmanaged.Error.IndexOutOfRange, str.eraseRangeFront(1));
    try testing.expectError(StringUnmanaged.Error.IndexOutOfRange, str.eraseRangeFront(999));
}

test "eraseRangeBack" {
    var str = try StringUnmanaged.initFromStr(alloc, "aaa_bbb_ccc");
    defer str.deinit(alloc);

    try str.eraseRangeBack(3);
    try expectEqlStr(u8, "aaa_bbb_", str.data());
    try str.eraseRangeBack(0);
    try expectEqlStr(u8, "aaa_bbb_", str.data());
    try str.eraseRangeBack(str.data().len);
    try expectEqlStr(u8, "", str.data());
}

test "eraseRangeAt" {
    var str = try StringUnmanaged.initFromStr(alloc, "aaa_bbb_ccc");
    defer str.deinit(alloc);

    try str.eraseRangeAt(4, 3);
    try expectEqlStr(u8, "aaa__ccc", str.data());
    try str.eraseRangeAt(4, 0);
    try expectEqlStr(u8, "aaa__ccc", str.data());
    try str.eraseRangeAt(4, 1);
    try expectEqlStr(u8, "aaa_ccc", str.data());
    try str.eraseRangeAt(3, 4);
    try expectEqlStr(u8, "aaa", str.data());
    try str.eraseRangeAt(0, 3);
    try expectEqlStr(u8, "", str.data());
}

test "isEmpty" {
    var str = StringUnmanaged.init();
    defer str.deinit(alloc);
    try expect(str.isEmpty());
    try str.insertSliceBack(alloc, "a");
    try expect(!str.isEmpty());
    str.clearRetainCapacity();
    try expect(str.isEmpty());
}

test "startsWithScalar" {
    var str = try StringUnmanaged.initFromStr(alloc, "abc");
    defer str.deinit(alloc);
    try expect(str.startsWithScalar('a'));
    try expect(!str.startsWithScalar('b'));
}

test "endsWithScalar" {
    var str = try StringUnmanaged.initFromStr(alloc, "abc");
    defer str.deinit(alloc);
    try expect(str.endsWithScalar('c'));
    try expect(!str.endsWithScalar('b'));
}

test "containsScalar" {
    var str = try StringUnmanaged.initFromStr(alloc, "abc");
    defer str.deinit(alloc);
    try expect(str.containsScalar('a'));
    try expect(str.containsScalar('b'));
    try expect(!str.containsScalar('d'));
}

test "countScalar" {
    var str = try StringUnmanaged.initFromStr(alloc, "aabcc");
    defer str.deinit(alloc);
    try expect(str.countScalar('a') == 2);
    try expect(str.countScalar('b') == 1);
    try expect(str.countScalar('c') == 2);
    try expect(str.countScalar('d') == 0);
}

test "setAt and getAt" {
    var str = try StringUnmanaged.initFromStr(alloc, "abc");
    defer str.deinit(alloc);

    try str.set(1, 'x');
    const val = try str.get(1);
    try expect(val.* == 'x');
    try expectEqlStr(u8, "axc", str.data());
}

test "eraseScalarFront and eraseScalarBack" {
    var str = try StringUnmanaged.initFromStr(alloc, "abc");
    defer str.deinit(alloc);

    try str.eraseScalarFront();
    try expectEqlStr(u8, "bc", str.data());
    try str.eraseScalarBack();
    try expectEqlStr(u8, "b", str.data());
}

test "reserve and shrinkUnusedCapacity" {
    var str = try StringUnmanaged.initCapacity(alloc, 5);
    defer str.deinit(alloc);

    try str.reserve(alloc, 10);
    try expect(str.cap >= 10);
    try str.insertSliceBack(alloc, "abc");
    try str.shrinkUnusedCapacity(alloc);
    try expect(str.cap == str.len);
}

test "boundary conditions for validateIndex and validateRange" {
    var str = try StringUnmanaged.initFromStr(alloc, "abc");
    defer str.deinit(alloc);

    try testing.expectError(StringUnmanaged.Error.IndexOutOfRange, str.getAt(3));
    try testing.expectError(StringUnmanaged.Error.IndexOutOfRange, str.getAt(10));
    try testing.expectError(StringUnmanaged.Error.IndexOutOfRange, str.eraseRangeAt(2, 2));
    try testing.expectError(StringUnmanaged.Error.IndexOutOfRange, str.eraseRangeAt(1, 3));
}

test "edge cases for eraseScalar" {
    var str = try StringUnmanaged.initFromStr(alloc, "abc");
    defer str.deinit(alloc);

    try str.eraseScalarAt(1);
    try expectEqlStr(u8, "ac", str.data());
    try testing.expectError(StringUnmanaged.Error.IndexOutOfRange, str.eraseScalarAt(10));
}

test "insertScalar" {
    var str = try StringUnmanaged.initCapacity(alloc, 5);
    defer str.deinit(alloc);

    try str.insertScalar(alloc, 0, 'x');
    try expectEqlStr(u8, "x", str.data());
    try str.insertScalar(alloc, 1, 'y');
    try expectEqlStr(u8, "xy", str.data());
    try str.insertScalar(alloc, 1, 'z');
    try expectEqlStr(u8, "xzy", str.data());
}
