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
const lib = @import("libpong");
const log = std.log;
const net = std.net;
const mem = std.mem;
const posix = std.posix;
const Server = @This();
const Client = @import("Client.zig");
const Buffer = std.ArrayListUnmanaged;
const RingBuffer = std.RingBuffer;
const State = lib.State;

gpa: mem.Allocator,
addr: net.Address,
socket: posix.socket_t,
clients: Buffer(Client),
pollfds: Buffer(posix.pollfd),
pong: State,
states: RingBuffer,

pub fn init(gpa: mem.Allocator, address: net.Address, flags: lib.cli.CliFlags) !Server {
    log.info("Initializing server at address: {any} with flags: {any}", .{ address, flags });
    return .{
        .pong = State.init(flags),
        .gpa = gpa,
        .socket = 0,
        .addr = address,
        .clients = Buffer(Client).empty,
        .pollfds = Buffer(posix.pollfd).empty,
        .states = try RingBuffer.init(gpa, lib.MessageBufferCapacity * lib.MessageTotalBytes),
    };
}

pub fn deinit(self: *Server) void {
    log.info("Deinitializing server at address: {any}", .{self.addr});
    for (self.clients.items) |*client| {
        log.debug("Deinitializing client: {any}", .{client.addr});
        client.deinit();
    }
    self.states.deinit(self.gpa);
    self.pollfds.deinit(self.gpa);
    self.clients.deinit(self.gpa);
    if (self.socket != -1) {
        log.debug("Closing server socket: {d}", .{self.socket});
        posix.close(self.socket);
    }
    log.info("Server deinitialized successfully.", .{});
    self.* = undefined;
}

pub fn listen(self: *Server) !void {
    log.info("Starting server at address: {any}", .{self.addr});
    const socket = posix.socket(
        self.addr.any.family,
        posix.SOCK.STREAM | posix.SOCK.NONBLOCK,
        posix.IPPROTO.TCP,
    ) catch |err| {
        log.err("{any} :: failed to open socket: {any}", .{ self.addr, err });
        return err;
    };
    errdefer posix.close(socket);

    log.debug("{any} :: Socket created successfully: {d}", .{ self.addr, socket });

    posix.setsockopt(
        socket,
        posix.SOL.SOCKET,
        posix.SO.REUSEADDR | posix.SO.REUSEPORT,
        &mem.toBytes(@as(c_int, 1)),
    ) catch |err| {
        log.err("{any} :: failed to configure socket: {any}", .{ self.addr, err });
        return err;
    };

    log.debug("{any} :: Socket options configured for reuse.", .{self.addr});

    posix.bind(
        socket,
        &self.addr.any,
        self.addr.getOsSockLen(),
    ) catch |err| {
        log.err("{any} :: failed to bind socket: {any}", .{ self.addr, err });
        return err;
    };

    log.info("{any} :: Socket bound successfully.", .{self.addr});

    posix.listen(
        socket,
        4,
    ) catch |err| {
        log.err("{any} :: failed to listen on socket: {any}", .{ self.addr, err });
        return err;
    };

    log.info("{any} :: Server now listening for connections.", .{self.addr});
    self.socket = socket;

    const server_poll: posix.pollfd = .{
        .fd = self.socket,
        .events = posix.POLL.IN,
        .revents = 0,
    };

    self.pollfds.append(self.gpa, server_poll) catch |err| {
        log.err("{any} :: failed to append server pollfd: {any}", .{ self.addr, err });
        return err;
    };

    log.debug("{any} :: Pollfd for server added successfully.", .{self.addr});
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
        log.err("{any} :: failed to accept client: {any}", .{ self.addr, err });
        return err;
    };
    log.info("{any} :: Accepted new client connection: {any}", .{ self.addr, address });

    var client = Client.init(self.gpa, address, socket) catch |err| {
        log.err("{any} :: failed to initialize client: {any}", .{ self.addr, err });
        return err;
    };
    errdefer client.deinit();

    const client_poll: posix.pollfd = .{
        .fd = client.sock,
        .events = posix.POLL.IN,
        .revents = 0,
    };

    self.pollfds.append(self.gpa, client_poll) catch |err| {
        log.err("{any} :: failed to append client pollfd: {any}", .{ self.addr, err });
        return err;
    };

    self.clients.append(self.gpa, client) catch |err| {
        log.err("{any} :: failed to append client {any} : {any}", .{ self.addr, client.addr, err });
        return err;
    };

    log.debug("{any} :: Client successfully added to server's pool: {any}", .{ self.addr, client.addr });
    return client;
}

pub fn getAssociatedClient(self: *const Server, pollfd: posix.pollfd) !*Client {
    log.debug("{any} :: Searching for client associated with pollfd: {d}", .{ self.addr, pollfd.fd });
    for (self.clients.items) |*client| {
        if (client.sock == pollfd.fd) {
            log.debug("{any} :: Found associated client: {any}", .{ self.addr, client.addr });
            return client;
        }
    }
    log.warn("{any} :: No client found for pollfd: {d}", .{ self.addr, pollfd.fd });
    return error.NotFound;
}

pub fn removeClient(self: *Server, client: *Client) void {
    log.info("{any} :: Removing client: {any}", .{ self.addr, client.addr });
    for (self.clients.items, 0..) |maybe_client, i| {
        if (maybe_client.sock == client.sock) {
            log.debug("{any} :: Removing client from client pool at index: {d}", .{ self.addr, i });
            _ = self.clients.swapRemove(i);
            break;
        }
    }

    for (self.pollfds.items, 0..) |pfd, i| {
        if (pfd.fd == client.sock) {
            log.debug("{any} :: Removing client's pollfd at index: {d}", .{ self.addr, i });
            _ = self.pollfds.swapRemove(i);
            break;
        }
    }
    log.info("{any} :: Client removed and connection closed: {any}", .{ self.addr, client.addr });
    client.deinit();
}
