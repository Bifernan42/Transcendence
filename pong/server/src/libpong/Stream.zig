// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Stream.zig                                         :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/26 15:51:39 by pollivie          #+#    #+#             //
//   Updated: 2025/01/26 15:51:40 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const net = std.net;
const mem = std.mem;
const heap = std.heap;
const posix = std.posix;
const Request = @import("Request.zig");
const Response = @import("Response.zig");
const Stream = @This();

address: net.Address,
socket: posix.socket_t,

pub fn init(address: net.Address, socket: posix.socket_t) Stream {
    return .{
        .address = address,
        .socket = socket,
    };
}

pub fn readRequestUntilComplete(stream: *Stream, request: *Request) !bool {
    var buffer: [64]u8 = undefined;
    while (!request.isComplete()) {
        const rbytes = posix.recv(stream.socket, buffer[0..], 0) catch |err| switch (err) {
            error.WouldBlock => continue,
        };

        if (rbytes == 0) {
            return request.isComplete();
        }
        try request.appendSlice(buffer[0..]);
    }
    return true;
}
pub fn readResponseUntilComplete(stream: *Stream, response: *Response) !bool {
    var buffer: [64]u8 = undefined;
    while (!response.isComplete()) {
        const rbytes = posix.recv(stream.socket, buffer[0..], 0) catch |err| switch (err) {
            error.WouldBlock => continue,
            else => return err,
        };

        if (rbytes == 0) {
            return response.isComplete();
        }
        try response.appendSlice(buffer[0..]);
    }
    return true;
}

pub fn sendRequest(stream: *Stream, request: *Request) !bool {
    if (request.serialized()) |buffer| {
        const len = buffer.len;
        var total: usize = 0;
        while (true) {
            const amount = posix.send(stream.socket, buffer[total..], 0) catch |err| switch (err) {
                error.WouldBlock => continue,
                else => return err,
            };
            total += amount;

            if (amount == 0 and total >= len) {
                return true;
            } else {
                return false;
            }
        }
    } else {
        return false;
    }
}
