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
const Connection = @This();
pub const ConnectionOption = struct {};

stream: Stream = undefined,
options: ConnectionOption,

pub fn init(address: net.Address, socket: posix.socket_t, options: ConnectionOption) Connection {
    return .{
        .stream = Stream.init(address, socket),
        .options = options,
    };
}

pub fn deinit(self: *Connection) void {
    self.stream.deinit();
}
