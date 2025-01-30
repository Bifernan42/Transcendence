// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Client.zig                                         :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/30 14:40:01 by pollivie          #+#    #+#             //
//   Updated: 2025/01/30 14:40:01 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const lib = @import("libpong");
const mem = std.mem;
const net = std.net;
const log = std.log;
const posix = std.posix;
const RingBuffer = std.RingBuffer;
const Player = @import("Player.zig");
const Client = @This();

address: net.Address = undefined,
socket: posix.socket_t = 0,
player: Player = Player.default,

pub fn init(address: net.Address, socket: posix.socket_t, player: Player) !Client {
    return .{
        .address = address,
        .socket = socket,
        .player = player,
    };
}

pub fn deinit(self: *Client) void {
    if (self.socket != -1) {
        posix.close(self.socket);
    }
    self.* = undefined;
}

pub fn readRequest(self: *Client, request: *lib.Request) !void {
    var buffer: [lib.getBufferSize(1, lib.Request)]u8 = undefined;
    const rbytes = try posix.recv(self.socket, buffer[0..], 0);
    if (rbytes != buffer.len) {
        return error.PartialRequest;
    }
    request.fromBytes(buffer[0..]);
}

pub fn sendResponse(self: *Client, response: *lib.Response) !void {
    const bytes = response.toBytes();
    const wbytes = try posix.send(self.socket, bytes[0..], 0);
    if (wbytes != bytes.len) {
        return error.PartialResponse;
    }
}

pub fn format(
    self: @This(),
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    _ = fmt;
    _ = options;
    try writer.print("{s}:{}:{d}", .{ self.address, self.socket, self.player.name });
}

pub const default: Client = .{
    .address = undefined,
    .socket = 0,
    .player = Player.default,
};
