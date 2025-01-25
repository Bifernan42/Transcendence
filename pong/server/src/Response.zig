// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Response.zig                                       :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/25 11:27:40 by pollivie          #+#    #+#             //
//   Updated: 2025/01/25 11:27:40 by pollivie         ###   ########.fr       //
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

pub fn Response(comptime value: Protocol.Kind) type {
    return struct {
        pub const Self = @This();
        pub const ProtocolResponse: type = switch (value) {
            .handshake => Protocol.Handshake.response,
            .config => Protocol.Config.response,
            .update => Protocol.Update.response,
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
                self.serialized = json.stringifyAlloc(allocator, response_object, Protocol.formating) catch {
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

        pub fn setResponseObjectOrInvalidate(self: *Self, response_object: ProtocolResponse) Error!void {
            const allocator = self.arena.allocator();
            const sanitized = json.parseFromValueLeaky(ProtocolResponse, allocator, response_object, .{}) catch |err| {
                std.log.err("unexpected error while setting inner Response object : {!}", .{err});
                self.status = .invalid;
                return Error.InvalidResponse;
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
