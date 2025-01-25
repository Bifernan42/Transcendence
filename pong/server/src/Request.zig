// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Request.zig                                        :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/25 11:27:28 by pollivie          #+#    #+#             //
//   Updated: 2025/01/25 11:27:29 by pollivie         ###   ########.fr       //
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

const Buffer = @import("Buffer.zig").Buffer;
const Client = @import("Client.zig");
const Pong = @import("Pong.zig");
const Protocol = @import("Protocol.zig");

pub fn Request(comptime value: Protocol.Kind) type {
    return struct {
        pub const Self = @This();
        pub const ProtocolRequest: type = switch (value) {
            .handshake => Protocol.Handshake.request,
            .config => Protocol.Config.request,
            .update => Protocol.Update.request,
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
                self.serialized = json.stringifyAlloc(allocator, resquest_object, Protocol.formating) catch {
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
            const allocator = self.arena;
            const request_buffer = self.serialized orelse return Error.IncompleteRequest;
            if (json.validate(allocator, request_buffer)) {
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
