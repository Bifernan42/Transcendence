// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Protocol.zig                                       :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/19 15:12:13 by pollivie          #+#    #+#             //
//   Updated: 2025/01/19 15:12:25 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const math = std.math;
const heap = std.heap;
const json = std.json;
const Allocator = mem.Allocator;
const assert = std.debug.assert;
const net = std.net;
const log = std.log;
const posix = std.posix;
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const builtin = @import("builtin");
const Pong = @import("Pong.zig");

const Protocol = @This();
pub const Kind = enum {
    none,
    handshake,
    config,
    update,
    acknowledgement,
    failure,
};
pub const Formatting: json.StringifyOptions = if (builtin.mode == .Debug) .{ .whitespace = .indent_4 } else .{};
pub const Delimiter: []const u8 = &.{0x1E};

pub fn Request(comptime value: Protocol.Kind) type {
    return struct {
        pub const Self = @This();
        pub const ProtocolRequest: type = switch (value) {
            .handshake => Protocol.Handshake.Request,
            .config => Protocol.Config.Request,
            .update => Protocol.Update.Request,
            .acknowledgement => Protocol.Acknowledgement,
            .failure => Protocol.Failure,
            .none => @compileError("incompatible type"),
        };

        arena: heap.ArenaAllocator,
        deserialized: ?ProtocolRequest,
        buffer: Buffer(u8),
        status: Status,
        serialized: ?[]const u8,
        length: ?usize,

        pub const Error = error{
            IncompleteRequest,
            InvalidRequest,
            EmptyRequest,
        } || json.ParseFromValueError;

        pub const Status = enum {
            empty,
            invalid,
            valid,
            incomplete,
            complete,
        };

        pub fn init(allocator: mem.Allocator) Self {
            var arena: heap.ArenaAllocator = .init(allocator);
            return .{
                .arena = arena,
                .deserialized = null,
                .serialized = null,
                .buffer = Buffer(u8).init(arena.allocator()),
                .status = .empty,
                .length = null,
            };
        }

        pub fn deinit(self: *Self) void {
            self.arena.deinit();
        }

        pub fn reset(self: *Self) void {
            defer _ = self.arena.reset(.retain_capacity);
            self.buffer.reset();
            self.status = .empty;
            self.deserialized = null;
            self.serialized = null;
            self.length = null;
        }

        pub fn isComplete(self: *const Self) bool {
            return self.status == .complete;
        }

        fn serializeOrError(self: *Self) Error![]const u8 {
            const allocator = self.arena.allocator();
            if (self.deserialized) |resquest_object| {
                self.serialized = json.stringifyAlloc(allocator, resquest_object, Protocol.Formatting) catch {
                    self.status = .invalid;
                    return Error.InvalidRequest;
                };
                self.status = .valid;
                return self.serialized.?;
            } else {
                return Error.EmptyRequest;
            }
        }

        pub fn serialize(self: *Self) Error![]const u8 {
            return switch (self.status) {
                .empty => Error.EmptyRequest,
                .invalid => Error.InvalidRequest,
                .incomplete => Error.IncompleteRequest,
                .complete => try self.serializeOrError(),
                .valid => self.serialized.?,
            };
        }

        pub fn setRequestObjectOrInvalidate(self: *Self, request_object: ProtocolRequest) Error!void {
            const allocator = self.arena.allocator();
            const sanitized = json.parseFromValueLeaky(ProtocolRequest, allocator, request_object, .{}) catch |err| {
                std.log.err("unexpected error while setting inner Request object : {!}", .{err});
                self.status = .invalid;
                return Error.InvalidRequest;
            };
            self.deserialized = sanitized;
            self.status = .valid;
        }

        pub fn appendUntilProtocolDelimiter(self: *Self, raw_request: []const u8) ![]const u8 {
            if (mem.indexOf(u8, raw_request, Protocol.Delimiter)) |found_boundary| {
                self.status = .complete;
                self.length = found_boundary + self.buffer.len();
                try self.buffer.pushSliceBack(raw_request[0..found_boundary]);
                self.serialized = self.buffer.slice();
                return raw_request[found_boundary..];
            } else {
                return raw_request[0..0];
            }
        }

        fn deserializeOrError(self: *Self) Error!ProtocolRequest {
            const allocator = self.arena.allocator();
            const request_buffer = self.serialized orelse return Error.IncompleteRequest;
            if (json.validate(allocator, request_buffer) catch false) {
                self.status = .valid;
                self.deserialized = json.parseFromSliceLeaky(ProtocolRequest, allocator, request_buffer, .{}) catch {
                    self.status = .invalid;
                    return Error.InvalidRequest;
                };
                return self.deserialized.?;
            } else {
                self.status = .invalid;
                return Error.InvalidRequest;
            }
        }

        pub fn deserialize(self: *Self) Error!ProtocolRequest {
            return switch (self.status) {
                .empty => Error.EmptyRequest,
                .invalid => Error.InvalidRequest,
                .incomplete => Error.IncompleteRequest,
                .complete => try self.deserializeOrError(),
                .valid => return self.deserialized.?,
            };
        }
    };
}

pub fn Response(comptime value: Protocol.Kind) type {
    return struct {
        pub const Self = @This();
        pub const ProtocolResponse: type = switch (value) {
            .handshake => Protocol.Handshake.Response,
            .config => Protocol.Config.Response,
            .update => Protocol.Update.Response,
            .acknowledgement => Protocol.Acknowledgement,
            .failure => Protocol.Failure,
            .none => {},
        };

        arena: heap.ArenaAllocator,
        deserialized: ?ProtocolResponse,
        buffer: Buffer(u8),
        status: Status,
        serialized: ?[]const u8,
        length: ?usize,

        pub const Error = error{
            IncompleteResponse,
            InvalidResponse,
            EmptyResponse,
        } || json.ParseFromValueError;

        pub const Status = enum {
            empty,
            invalid,
            valid,
            incomplete,
            complete,
        };

        pub fn init(allocator: mem.Allocator) Self {
            var arena: heap.ArenaAllocator = .init(allocator);
            return .{
                .arena = arena,
                .deserialized = null,
                .serialized = null,
                .buffer = Buffer(u8).init(arena.allocator()),
                .status = .empty,
                .length = null,
            };
        }

        pub fn deinit(self: *Self) void {
            self.arena.deinit();
        }

        pub fn reset(self: *Self) void {
            defer _ = self.arena.reset(.retain_capacity);
            self.buffer.reset();
            self.status = .empty;
            self.deserialized = null;
            self.serialized = null;
            self.length = null;
        }

        pub fn isComplete(self: *const Self) bool {
            return self.status == .complete;
        }

        fn serializeOrError(self: *Self) Error![]const u8 {
            const allocator = self.arena.allocator();
            if (self.deserialized) |response_object| {
                self.serialized = json.stringifyAlloc(allocator, response_object, Protocol.Formatting) catch {
                    self.status = .invalid;
                    return Error.InvalidResponse;
                };
                self.status = .valid;
                return self.serialized.?;
            } else {
                return Error.EmptyResponse;
            }
        }

        pub fn serialize(self: *Self) Error![]const u8 {
            return switch (self.status) {
                .empty => Error.EmptyResponse,
                .invalid => Error.InvalidResponse,
                .incomplete => Error.IncompleteResponse,
                .complete => try self.serializeOrError(),
                .valid => self.serialized.?,
            };
        }

        pub fn setResponseObjectOrInvalidate(self: *Self, response_object: ProtocolResponse) void {
            self.deserialized = response_object;
            self.status = .valid;
        }

        pub fn appendUntilProtocolDelimiter(self: *Self, raw_request: []const u8) ![]const u8 {
            if (mem.indexOf(u8, raw_request, Protocol.Delimiter)) |found_boundary| {
                self.status = .complete;
                self.length = found_boundary + self.buffer.len();
                try self.buffer.pushSliceBack(raw_request[0..found_boundary]);
                self.serialized = self.buffer.slice();
                return raw_request[found_boundary..];
            } else {
                return raw_request[0..0];
            }
        }

        fn deserializeOrError(self: *Self) Error!ProtocolResponse {
            const allocator = self.arena;
            const response_buffer = self.serialized orelse return Error.IncompleteResponse;
            if (json.validate(allocator, response_buffer)) {
                self.status = .valid;
                self.deserialized = json.parseFromSliceLeaky(ProtocolResponse, allocator, response_buffer, .{}) catch {
                    self.status = .invalid;
                    return Error.InvalidResponse;
                };
                return self.deserialized.?;
            } else {
                self.status = .invalid;
                return Error.InvalidResponse;
            }
        }

        pub fn deserialize(self: *Self) Error!ProtocolResponse {
            return switch (self.status) {
                .empty => Error.EmptyResponse,
                .invalid => Error.InvalidResponse,
                .incomplete => Error.IncompleteResponse,
                .complete => try self.deserializeOrError(),
                .valid => return self.deserialized.?,
            };
        }
    };
}

pub fn Buffer(comptime T: type) type {
    return struct {
        pub const Self = @This();
        list: ArrayListUnmanaged(T),
        allocator: mem.Allocator,

        const empty: []T = &.{};

        pub fn init(allocator: mem.Allocator) Self {
            return .{
                .list = ArrayListUnmanaged(T).empty,
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

        pub fn popSliceFront(self: *Self, allocator: mem.Allocator, length: usize) !?[]T {
            if (self.list.items.len < length) return null;
            const result = try allocator.alloc(T, length);
            @memcpy(result, self.list.items[0..length]);
            try self.list.replaceRange(self.allocator, 0, length, empty);
            return result;
        }

        pub fn popSliceBack(self: *Self, allocator: mem.Allocator, length: usize) !?[]T {
            if (self.list.items.len < length) return null;
            const result = try allocator.alloc(T, length);
            const list_len = self.list.len;
            @memcpy(result, self.list.items[list_len -| length..]);
            try self.list.replaceRange(self.allocator, list_len -| length, length, empty);
            return result;
        }

        pub fn popSliceAt(self: *Self, allocator: mem.Allocator, index: usize, length: usize) !?[]T {
            if (self.list.items.len < (index + length)) return null;
            const result = try allocator.alloc(T, length);
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

pub const Handshake = struct {
    pub const Request = struct {
        client_id: []const u8 = "none",
        timestamp: i64 = 0,

        pub const default: Handshake.Request = .{
            .client_id = "none",
            .timestamp = 0,
        };

        pub fn format(
            self: @This(),
            comptime formats: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = formats;
            _ = options;
            try json.stringify(self, Formatting, writer);
        }
    };

    pub const Response = struct {
        token: u64 = 0,
        status: bool = true,
        timestamp: i64 = 0,

        pub const default: Handshake.Response = .{
            .token = 0,
            .status = true,
            .timestamp = 0,
        };

        pub fn format(
            self: @This(),
            comptime formats: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = formats;
            _ = options;
            try json.stringify(self, Formatting, writer);
        }
    };
};

pub const Config = struct {
    pub const Request = struct {
        token: u64 = 0,
        timestamp: i64 = 0,

        pub const default: Config.Request = .{
            .token = 0,
            .timestamp = 0,
        };

        pub fn format(
            self: @This(),
            comptime formats: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = formats;
            _ = options;
            try json.stringify(self, Formatting, writer);
        }
    };

    pub const Response = struct {
        status: bool = true,
        state: Pong.GameState = Pong.GameState.default,
        timestamp: i64 = 0,

        pub const default: Config.Response = .{
            .status = true,
            .state = Pong.GameState.default,
            .timestamp = 0,
        };

        pub fn format(
            self: @This(),
            comptime formats: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = formats;
            _ = options;
            try json.stringify(self, Formatting, writer);
        }
    };
};

pub const Update = struct {
    pub const Request = struct {
        token_id: u64,
        event: Pong.Player.Event = Pong.Player.Event.default,
        timestamp: i64 = 0,

        pub const default: Update.Request = .{
            .token_id = 0,
            .event = Pong.Player.Event.default,
            .timestamp = 0,
        };

        pub fn format(
            self: @This(),
            comptime formats: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = formats;
            _ = options;
            try json.stringify(self, Formatting, writer);
        }
    };

    pub const Response = struct {
        state: Pong.GameState = Pong.GameState.default,
        timestamp: i64 = 0,

        pub const default: Update.Response = .{
            .state = Pong.GameState.default,
            .timestamp = 0,
        };

        pub fn format(
            self: @This(),
            comptime formats: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = formats;
            _ = options;
            try json.stringify(self, Formatting, writer);
        }
    };
};

pub const Acknowledgement = struct {
    id: u64 = 0,
    bytes: u64 = 0,
    delay: i64 = 0,
    timestamp: i64 = 0,

    pub const default: Acknowledgement = .{
        .id = 0,
        .bytes = 0,
        .delay = 0,
        .timestamp = 0,
    };

    pub fn format(
        self: @This(),
        comptime formats: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = formats;
        _ = options;
        try json.stringify(self, Formatting, writer);
    }
};

pub const Failure = struct {
    from: Kind = .none,
    reason: []const u8 = "",
    timestamp: i64 = 0,

    pub const default: Failure = .{
        .from = .none,
        .reaon = "",
        .timestamp = 0,
    };

    pub fn format(
        self: @This(),
        comptime formats: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = formats;
        _ = options;
        try json.stringify(self, Formatting, writer);
    }
};
