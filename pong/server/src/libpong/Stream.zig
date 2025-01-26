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
const Stream = @This();
pub const StreamOption = struct {};

address: net.Address,
socket: posix.socket_t,

pub fn init(address: net.Address, socket: posix.socket_t) Stream {
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
