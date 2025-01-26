// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Client.zig                                         :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/26 11:21:13 by pollivie          #+#    #+#             //
//   Updated: 2025/01/26 11:21:13 by pollivie         ###   ########.fr       //
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

pub const ClientOptions = struct {
    non_blocking: bool = true,
    tickrate: u16 = 60,
    timeout: u16 = 200,
    max_connection: u64 = 2,
    socket_type: u32 = posix.SOCK.STREAM | posix.SOCK.NONBLOCK,
    protocol: u16 = posix.IPPROTO.TCP,
};

pub const Client = struct {
    allocator: mem.Allocator,
    options: ClientOptions,
    stream: Stream,
    clock: time.Timer,

    pub fn init(allocator: mem.Allocator, options: ClientOptions) Client {
        return .{
            .allocator = allocator,
            .options = options,
            .stream = Stream{},
            .clock = time.Timer.start() catch unreachable,
        };
    }

    pub fn deinit(self: *Client) void {
        self.stream.deinit();
        self.* = undefined;
    }

    pub const Stream = struct {
        address: net.Address = undefined,
        socket: posix.socket_t = 0,

        pub fn init(address: net.Address, options: ClientOptions) !Stream {
            const domain = address.any.family;
            const protocol = options.protocol;
            const socket_type = options.socket_type;
            const socket = try posix.socket(domain, socket_type, protocol);
            return .{
                .address = address,
                .socket = socket,
            };
        }

        pub fn deinit(self: *Stream) void {
            if (self.socket != -1) {
                posix.close(self.socket);
            }
            self.* = undefined;
        }

        pub fn connect(self: *Stream) posix.ConnectError!void {
            try posix.connect(
                self.socket,
                self.address.any,
                self.address.getOsSockLen(),
            );
        }

        pub fn connectOrTimeout(self: *Stream, clock: *Clock) error{Timeout}!void {
            while (!clock.didTimeout()) {
                posix.connect(self.socket, &self.address.any, self.address.getOsSockLen()) catch {
                    continue;
                };
                return;
            }
            return error.Timeout;
        }

        pub const ReadIntoErr = error{} || posix.RecvFromError || mem.Allocator.Error;

        pub fn readIntoResponse(self: *Stream, response: *Response) ReadIntoErr!void {
            const allocator = response.arena.allocator();
            var buffer: [64]u8 = undefined;
            while (true) {
                const rbytes = try posix.recv(self.socket, buffer[0..], 0);
                if (rbytes == 0) {
                    return;
                }
                try response.buffer.appendSlice(allocator, buffer[0..rbytes]);
            }
        }

        pub fn readIntoResponseOrTimeout(self: *Stream, response: *Response, clock: *Clock) error{Timeout}!bool {
            const allocator = response.arena.allocator();
            var buffer: [64]u8 = undefined;

            while (!clock.didTimeout()) {
                const rbytes = posix.recv(self.socket, buffer[0..], 0) catch {
                    continue;
                };

                if (rbytes == 0) {
                    return true;
                }
                response.buffer.appendSlice(allocator, buffer[0..rbytes]) catch unreachable;
            }
            return false;
        }

        pub const SendRequestErr = error{empty_request} || posix.SendError;

        pub fn sendRequest(self: *Stream, request: *Request) SendRequestErr!void {
            const buffer = request.serialized() orelse return error.empty_request;
            const total_len = buffer.len;
            var sent_bytes: usize = 0;

            while (sent_bytes < total_len) {
                const wbytes = try posix.send(self.socket, buffer[sent_bytes..], 0);
                sent_bytes += wbytes;
                if (wbytes == 0) {
                    return;
                }
            }
        }

        pub fn sendRequestOrTimeout(self: *Stream, request: *Request, clock: *Clock) error{ Timeout, EmptyRequest }!bool {
            const buffer = request.serialized() orelse return error.EmptyRequest;
            var sent_bytes: usize = 0;

            while (!clock.didTimeout()) {
                const wbytes = posix.send(self.socket, buffer[sent_bytes..], 0) catch {
                    continue;
                };
                sent_bytes += wbytes;
                if (wbytes == 0) {
                    return true;
                }
            }
            return false;
        }
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

        pub fn jsonSerialize(self: *Response, object: anytype) !void {
            const allocator = self.arena.allocator();
            const items = try fmt.allocPrint(allocator, "{}" ++ root.protocol.Delimiter, .{object});
            try self.buffer.appendSlice(allocator, items);
        }

        pub fn jsonDeserialize(self: *Response, comptime T: type, into: *T) !void {
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
