// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Connection.zig                                     :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/26 15:49:45 by pollivie          #+#    #+#             //
//   Updated: 2025/01/26 15:49:46 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const Stream = @import("Stream.zig");
const std = @import("std");
const net = std.net;
const mem = std.mem;
const posix = std.posix;
const heap = std.heap;
const InternalStates = @import("protocol.zig").ClientInfo;
const Request = @import("Request.zig");
const Response = @import("Response.zig");
const Connection = @This();

gpa: mem.Allocator,
response: Response,
request: Request,
stream: Stream,
states: InternalStates,

pub fn init(gpa: mem.Allocator, address: net.Address, socket: posix.socket_t) Connection {
    return .{
        .gpa = gpa,
        .stream = Stream.init(address, socket),
        .request = Request.init(gpa),
        .response = Response.init(gpa),
        .states = .{},
    };
}

pub fn deinit(self: *Connection) void {
    self.response.deinit();
    self.request.deinit();
    self.stream.deinit();
}

pub fn format(
    self: @This(),
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    _ = fmt;
    _ = options;

    try writer.print("{}", .{self.stream.address});
}
