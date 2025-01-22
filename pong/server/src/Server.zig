// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Server.zig                                         :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/22 20:52:57 by pollivie          #+#    #+#             //
//   Updated: 2025/01/22 20:52:57 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const net = std.net;
const log = std.log;
const mem = std.mem;
const json = std.json;
const heap = std.heap;
const time = std.time;
const posix = std.posix;
const process = std.process;
const io = std.io;
const builtin = @import("builtin");

const Client = @import("Client.zig");
const Config = @import("Config.zig");
const Protocol = @import("Protocol.zig");
const Pong = @import("Pong.zig");
const Server = @This();

gpa: mem.Allocator,
config: Config,
address: net.Address,
arenas: std.ArrayListUnmanaged(heap.ArenaAllocator),
clients: std.ArrayListUnmanaged(Client),
pollfds: std.ArrayListUnmanaged(posix.pollfd),

pub fn init(gpa: mem.Allocator, config: Config) !Server {
    return .{
        .address = try net.Address.parseIp("127.0.0.1", 8080),
        .arenas = std.ArrayListUnmanaged(heap.ArenaAllocator).empty,
        .clients = std.ArrayListUnmanaged(Client).empty,
        .pollfds = std.ArrayListUnmanaged(posix.pollfd).empty,
        .gpa = gpa,
        .config = config,
    };
}

pub fn deinit(server: *Server) void {
    _ = server;
}
