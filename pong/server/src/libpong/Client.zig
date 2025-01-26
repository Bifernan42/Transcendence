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
const net = std.net;
const fmt = std.fmt;
const mem = std.mem;
const heap = std.heap;
const posix = std.posix;
const Connection = root.Connection;
const Client = @This();

pub const ClientOptions = struct {};

allocator: mem.Allocator,
options: ClientOptions,
connection: Connection,

pub fn init(allocator: mem.Allocator, options: ClientOptions) Client {
    return .{
        .allocator = allocator,
        .options = options,
        .connection = .{},
    };
}

pub fn deinit(self: *Client) void {
    self.* = undefined;
}
