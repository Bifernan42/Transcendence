// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Server.zig                                         :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/27 12:48:20 by pollivie          #+#    #+#             //
//   Updated: 2025/01/27 12:48:21 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const root = @import("root.zig");
const log = std.log;
const net = std.net;
const mem = std.mem;
const posix = std.posix;
const Server = @This();
const Client = @import("Client.zig");
const Buffer = std.ArrayListUnmanaged;
const RingBuffer = std.RingBuffer;

gpa: mem.Allocator,
addr: net.Address,
socket: posix.socket_t,
clients: Buffer(Client),
pollfds: Buffer(posix.pollfd),
flags: root.cli.CliFlags,
states: RingBuffer,

pub fn init(gpa: mem.Allocator, address: net.Address, flags: root.cli.CliFlags) !Server {
    return .{
        .gpa = gpa,
        .flags = flags,
        .socket = 0,
        .addr = address,
        .clients = Buffer(Client).empty,
        .pollfds = Buffer(posix.pollfd).empty,
        .states = try RingBuffer.init(gpa, 64 * root.MessageTotalBytes),
    };
}

pub fn deinit(self: *Server) void {
    for (self.clients.items) |*client| {
        client.deinit();
    }
    self.states.deinit(self.gpa);
    self.pollfds.deinit(self.gpa);
    self.clients.deinit(self.gpa);
    if (self.socket != -1) {
        posix.close(self.socket);
    }
    self.* = undefined;
}

pub fn listen(self: *Server) !void {
    const socket = posix.socket(
        self.addr.any.family,
        posix.SOCK.STREAM | posix.SOCK.NONBLOCK,
        posix.IPPROTO.TCP,
    ) catch |err| {
        log.err("{} :: failed to open socket :: {}", .{ self.addr, err });
        return err;
    };
    errdefer posix.close(socket);

    posix.setsockopt(
        socket,
        posix.SOL.SOCKET,
        posix.SO.REUSEADDR | posix.SO.REUSEPORT,
        &mem.toBytes(@as(c_int, 1)),
    ) catch |err| {
        log.err("{} :: failed to configure socket :: {}", .{ self.addr, err });
        return err;
    };

    posix.bind(
        socket,
        &self.addr.any,
        self.addr.getOsSockLen(),
    ) catch |err| {
        log.err("{} :: failed to bind socket :: {}", .{ self.addr, err });
        return err;
    };

    posix.listen(
        socket,
        4,
    ) catch |err| {
        log.err("{} :: failed to listen with socket :: {}", .{ self.addr, err });
        return err;
    };

    self.socket = socket;

    const server_poll: posix.pollfd = .{
        .fd = self.socket,
        .events = posix.POLL.IN,
        .revents = 0,
    };

    self.pollfds.append(self.gpa, server_poll) catch |err| {
        log.err("{} :: failed to append server_pollfd :: {}", .{ self.addr, err });
        return err;
    };
}

pub fn accept(self: *Server) !Client {
    var address: net.Address = undefined;
    var address_len: posix.socklen_t = @sizeOf(net.Address);

    const socket = posix.accept(
        self.socket,
        &address.any,
        &address_len,
        posix.SOCK.NONBLOCK,
    ) catch |err| {
        log.err("{} :: failed to accept client. :: {!}", .{ self.addr, err });
        return err;
    };
    log.debug("{} :: successfully accepted client's connection request. {}", .{ self.addr, address });

    var client = Client.init(self.gpa, address, socket) catch |err| {
        log.err("{} :: failed to init client. :: {!}", .{ self.addr, err });
        return err;
    };
    errdefer client.deinit();

    const client_poll: posix.pollfd = .{
        .fd = client.sock,
        .events = posix.POLL.IN,
        .revents = 0,
    };

    self.pollfds.append(self.gpa, client_poll) catch |err| {
        log.err("{} :: failed to append client_pollfd {} :: {!}", .{ self.addr, client.addr, err });
        return err;
    };

    self.clients.append(self.gpa, client) catch |err| {
        log.err("{} :: failed to append client {} :: {!}", .{ self.addr, client.addr, err });
        return err;
    };
    return client;
}

pub fn getAssociatedClient(self: *const Server, pollfd: posix.pollfd) !*Client {
    for (self.clients.items) |*client| {
        if (client.sock == pollfd.fd) {
            return client;
        }
    }
    return error.NotFound;
}

pub fn removeClient(self: *Server, client: *Client) void {
    log.debug("{} :: removing client from server's client pool :: {}", .{ self.addr, client.addr });
    for (self.clients.items, 0..) |maybe_client, i| {
        if (maybe_client.sock == client.sock) {
            _ = self.clients.swapRemove(i);
            break;
        }
    }

    for (self.pollfds.items, 0..) |pfd, i| {
        if (pfd.fd == client.sock) {
            _ = self.pollfds.swapRemove(i);
            break;
        }
    }
    log.debug("{} :: client closed :: {}", .{ self.addr, client.addr });
    client.deinit();
}
