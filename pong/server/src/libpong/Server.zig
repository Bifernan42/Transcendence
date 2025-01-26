// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Server.zig                                         :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/26 10:50:39 by pollivie          #+#    #+#             //
//   Updated: 2025/01/26 10:50:40 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const root = @import("root.zig");
const json = std.json;
const Pair = root.Pair;
const net = std.net;
const fmt = std.fmt;
const mem = std.mem;
const heap = std.heap;
const posix = std.posix;
const Buffer = std.ArrayListUnmanaged;
const Map = std.AutoArrayHashMapUnmanaged;
const time = std.time;
const Clock = root.Clock;

pub const ServerOptions = struct {
    non_blocking: bool = true,
    tickrate: i64 = 60,
    timeout: i64 = 200,
    max_connection: u64 = 2,
};

pub const Server = struct {
    allocator: mem.Allocator,
    address: net.Address,
    socket: posix.socket_t,
    options: ServerOptions,
    clock: time.Timer,
    pollfds: Buffer(posix.pollfd),
    clients: Buffer(Server.Connection),
    requests: Map(i64, Pair(posix.socket_t, Server.Request)),
    responses: Map(i64, Pair(posix.socket_t, Server.Response)),

    pub fn init(allocator: mem.Allocator, address: net.Address, options: ServerOptions) Server {
        return .{
            .allocator = allocator,
            .address = address,
            .socket = 0,
            .clock = time.Timer.start() catch unreachable,
            .options = options,
            .pollfds = Buffer(posix.pollfd).empty,
            .clients = Buffer(Server.Connection).empty,
            .requests = Map(i64, Pair(posix.socket_t, Request)).empty,
            .responses = Map(i64, Pair(posix.socket_t, Response)).empty,
        };
    }

    pub fn deinit(self: *Server) void {
        if (self.socket != -1) {
            posix.close(self.socket);
        }

        for (self.clients.items) |client| {
            posix.close(client.socket);
        }

        var req_it = self.requests.iterator();
        while (req_it.next()) |*entry| {
            entry.value_ptr.deinit();
        }

        var res_it = self.responses.iterator();
        while (res_it.next()) |*entry| {
            entry.value_ptr.deinit();
        }

        self.clients.deinit(self.allocator);
        self.pollfds.deinit(self.allocator);
        self.requests.deinit(self.allocator);
        self.responses.deinit(self.allocator);
        self.* = undefined;
    }

    pub const Connection = struct {
        address: net.Address,
        socket: posix.socket_t,
        clock: Clock,

        pub fn init(address: net.Address, socket: posix.socket_t) Connection {
            return .{
                .address = address,
                .socket = socket,
            };
        }

        pub fn deinit(self: *Connection) void {
            if (self.socket != -1) {
                posix.close(self.socket);
            }
            self.* = undefined;
        }

        pub const Stream = struct {};
    };

    pub const Request = struct {
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

        pub fn jsonSerialize(self: *Request, object: anytype) !void {
            const allocator = self.arena.allocator();
            const items = try fmt.allocPrint(allocator, "{}" ++ root.protocol.Delimiter, .{object});
            try self.buffer.appendSlice(allocator, items);
        }

        pub fn serialized(self: *Request) ?[]const u8 {
            if (mem.indexOf(u8, self.internalSlice(), root.protocol.Delimiter)) |found| {
                return self.internalSlice()[0..found];
            } else {
                return null;
            }
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
    };

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
            return std.mem.indexOf(u8, items, root.protocol.Delimiter) != null;
        }

        pub fn jsonSerialize(self: *Request, object: anytype) !void {
            const allocator = self.arena.allocator();
            const items = try fmt.allocPrint(allocator, "{}" ++ root.protocol.Delimiter, .{object});
            try self.buffer.appendSlice(allocator, items);
        }

        pub fn serialized(self: *Request) ?[]const u8 {
            if (mem.indexOf(u8, self.internalSlice(), root.protocol.Delimiter)) |found| {
                return self.internalSlice()[0..found];
            } else {
                return null;
            }
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
    };
};
