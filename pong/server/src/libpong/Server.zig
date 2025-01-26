// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Server.zig                                         :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/26 10:50:39 by pollivie          #+#    #+#             //
//   Updated: 2025/01/26 10:50:40 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const json = std.json;
const net = std.net;
const fmt = std.fmt;
const mem = std.mem;
const heap = std.heap;
const posix = std.posix;
const Buffer = std.ArrayListUnmanaged;
const Map = std.AutoArrayHashMapUnmanaged;
const Request = @import("Request.zig");
const Response = @import("Response.zig");
const Connection = @import("Connection.zig");
const root = @import("root.zig");
const Server = @This();

pub const ServerOptions = struct {};
pub const ListenOptions = struct {
    ip: []const u8 = "127.0.0.1",
    port: u16 = 8080,
    sock_type: u32 = posix.SOCK.STREAM | posix.SOCK.NONBLOCK,
    sock_prot: u32 = posix.IPPROTO.TCP,
    max_conn: u31 = 2,
};

allocator: mem.Allocator,
address: net.Address,
socket: posix.socket_t,
options: ServerOptions,
pollfds: Buffer(posix.pollfd),
clients: Buffer(Connection),

pub fn init(allocator: mem.Allocator, options: ServerOptions) Server {
    return .{
        .allocator = allocator,
        .address = undefined,
        .socket = 0,
        .options = options,
        .pollfds = Buffer(posix.pollfd).empty,
        .clients = Buffer(Server.Connection).empty,
    };
}

pub fn deinit(self: *Server) void {
    if (self.socket != -1) {
        posix.close(self.socket);
    }
    self.clients.deinit(self.allocator);
    self.pollfds.deinit(self.allocator);
    self.* = undefined;
}

pub fn listen(server: *Server, options: ListenOptions) !void {
    const address = try net.Address.parseIp(
        options.ip,
        options.port,
    );

    const socket = try posix.socket(
        address.any.family,
        options.sock_type,
        options.sock_prot,
    );
    errdefer posix.close(socket);

    try posix.setsockopt(
        socket,
        posix.SOL.SOCKET,
        posix.SO.REUSEADDR | posix.SO.REUSEPORT,
        std.mem.asBytes(&@as(c_int, 1)),
    );

    try posix.bind(
        socket,
        &address.any,
        address.getOsSockLen(),
    );

    try posix.listen(
        socket,
        options.max_conn,
    );

    server.socket = socket;
    server.address = address;

    const server_poll: posix.pollfd = .{
        .fd = socket,
        .events = posix.POLL.IN,
        .revents = 0,
    };

    try server.pollfds.append(server.allocator, server_poll);
}
