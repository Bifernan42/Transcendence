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
const posix = std.posix;
const net = std.net;
const log = std.log;
const json = std.json;
const time = std.time;
const mem = std.mem;
const Protocol = @import("Protocol.zig");
const Client = @import("Client.zig").Client;
const ClientRequest = @import("Client.zig").ClientRequest;
const ClientResponse = @import("Client.zig").ClientResponse;
const Config = @import("Config.zig");
const utils = @import("utils.zig");
const Simulation = @import("Simulation.zig");
const Server = @This();

gpa: std.mem.Allocator,
config: Config,
address: net.Address,
socket: posix.socket_t,
simulation: Simulation,
clients: std.ArrayListUnmanaged(Client),
pollfds: std.ArrayListUnmanaged(posix.pollfd),

pub fn init(gpa: std.mem.Allocator, config: Config) !Server {
    const address = try net.Address.parseIp(config.ip, config.port);
    const socket = try createSocket(address);
    errdefer posix.close(socket);

    return .{
        .gpa = gpa,
        .config = config,
        .socket = socket,
        .address = address,
        .simulation = Simulation.init(gpa, config),
        .clients = .empty,
        .pollfds = .empty,
    };
}

pub fn deinit(self: *Server) void {
    if (self.socket != -1) {
        posix.close(self.socket);
    }
    self.clients.deinit(self.gpa);
    self.pollfds.deinit(self.gpa);
    self.simulation.deinit();
}

fn createSocket(address: net.Address) !posix.socket_t {
    const socket = try posix.socket(
        address.any.family,
        posix.SOCK.STREAM | posix.SOCK.NONBLOCK,
        posix.IPPROTO.TCP,
    );

    try posix.setsockopt(
        socket,
        posix.SOL.SOCKET,
        posix.SO.REUSEADDR,
        &std.mem.toBytes(@as(c_int, 1)),
    );

    try posix.bind(
        socket,
        &address.any,
        address.getOsSockLen(),
    );

    try posix.listen(
        socket,
        10,
    );

    return socket;
}

pub fn run(self: *Server) !void {
    defer self.deinit();

    const sleep_nano: u64 = @divTrunc(time.ns_per_s, @as(u64, self.config.tickrate));
    try self.pollfds.append(self.gpa, .{
        .fd = self.socket,
        .events = posix.POLL.IN,
        .revents = 0,
    });

    while (true) {
        try self.tick();
        posix.nanosleep(0, sleep_nano);
    }
}

fn tick(self: *Server) !void {
    const pollfds = self.pollfds.items;
    _ = try posix.poll(pollfds, 0);

    for (pollfds) |pollfd| {
        if (pollfd.fd == self.socket and pollfd.revents & posix.POLL.IN != 0) {
            try self.acceptClient();
            continue;
        }

        if (pollfd.revents != 0) {
            const client = self.getClientBySocket(pollfd.fd) orelse continue;

            if (pollfd.revents & posix.POLL.IN != 0) {
                self.handleClientRequest(client) catch |err| {
                    log.err("Error handling client: {!}", .{err});
                    self.removeClient(client);
                };
            }
        }
    }
}

fn acceptClient(self: *Server) !void {
    var client_addr: net.Address = undefined;
    var socklen: posix.socklen_t = @sizeOf(net.Address);

    const client_socket = try posix.accept(
        self.socket,
        &client_addr.any,
        &socklen,
        posix.SOCK.NONBLOCK,
    );

    var client = Client.init(
        self.gpa,
        client_addr,
        client_socket,
    );
    errdefer client.deinit();

    try self.clients.append(
        self.gpa,
        client,
    );
    errdefer _ = self.clients.swapRemove(self.clients.items.len - 1);

    const client_pfd: posix.pollfd = .{
        .fd = client_socket,
        .events = posix.POLL.IN,
        .revents = 0,
    };

    try self.pollfds.append(
        self.gpa,
        client_pfd,
    );
}

fn handleClientRequest(server: *Server, client: *Client) !void {
    var result: bool = false;
    switch (client.state) {
        .connected => {
            var request = client.getHandshakeRequest();
            defer request.deinit();

            result = server.handleHandshakeRequestConnected(client, &request) catch |err| {
                std.log.err("{!}", .{err});
                client.transition(.disconnected);
                return error.Closed;
            };
            client.transition(.authentificated);
        },
        .disconnected => {
            var request = client.getHandshakeRequest();
            defer request.deinit();

            result = server.handleHandshakeRequestDisconnected(client, &request) catch |err| {
                std.log.err("{!}", .{err});
                client.transition(.disconnected);
                return error.Closed;
            };
            client.transition(.authentificated);
        },
        .authentificated => {
            var request = client.getConfigRequest();
            defer request.deinit();

            result = server.handleConfigRequest(client, &request) catch |err| {
                std.log.err("{!}", .{err});
                client.transition(.disconnected);
                return error.Closed;
            };

            client.transition(.waiting);
        },
        .waiting => {
            var request = client.getUpdateRequest();
            defer request.deinit();

            result = server.handleUpdateRequest(client, &request) catch |err| {
                std.log.err("{!}", .{err});
                client.transition(.disconnected);
                return error.Closed;
            };

            client.transition(.playing);
        },
        .playing => {
            var request = client.getUpdateRequest();
            defer request.deinit();

            result = server.handleUpdateRequest(client, &request) catch |err| {
                std.log.err("{!}", .{err});
                client.transition(.disconnected);
                return error.Closed;
            };

            client.transition(.done);
        },
        .done => {
            var request = client.getAcknowledgementRequest();
            defer request.deinit();

            result = server.handleAcknowledgementRequest(client, &request) catch |err| {
                std.log.err("{!}", .{err});
                client.transition(.disconnected);
                return error.Closed;
            };

            client.transition(.waiting);
        },
    }

    log.info("{} {s}.", .{ server.address, if (result) "handled" else "failed to handle" });
}

fn handleHandshakeRequestConnected(server: *Server, client: *Client, request: *Protocol.Request(.handshake)) !bool {
    std.debug.assert(client.state == .connected);

    var simulation = server.simulation;
    const handshake: Protocol.Handshake.Request = try request.deserialize();

    switch (simulation.kind) {
        .local_ai => {
            switch (simulation.whoIs(handshake.client_id)) {
                .player1 => {
                    var response = client.getHandshakeResponse();
                    defer response.deinit();

                    if (!simulation.internal.isRegistered(.player1)) {
                        simulation.internal.register(.player1, 1);
                    }

                    const validation: Protocol.Handshake.Response = .{
                        .token = 1,
                        .status = true,
                        .timestamp = server.now(),
                    };

                    response.setResponseObjectOrInvalidate(validation);
                    return try client.sendMessage(response.serialize() catch unreachable);
                },
                else => {
                    var response = client.getFailureResponse();

                    const report: Protocol.Failure = .{
                        .from = .handshake,
                        .reason = "invalid request.",
                        .timestamp = server.now(),
                    };

                    response.setResponseObjectOrInvalidate(report);
                    return try client.sendMessage(response.serialize() catch unreachable);
                },
            }
        },
        .local_mp, .remote_mp => {
            switch (simulation.whoIs(handshake.client_id)) {
                .player1, .player2 => |player| {
                    var response = client.getHandshakeResponse();
                    defer response.deinit();
                    const id: u64 = if (player == .player1) 1 else 2;

                    if (!simulation.internal.isRegistered(player)) {
                        simulation.internal.register(player, id);
                    }

                    const validation: Protocol.Handshake.Response = .{
                        .token = id,
                        .status = true,
                        .timestamp = server.now(),
                    };

                    response.setResponseObjectOrInvalidate(validation);
                    return try client.sendMessage(response.serialize() catch unreachable);
                },
                else => {
                    var response = client.getFailureResponse();

                    const report: Protocol.Failure = .{
                        .from = .handshake,
                        .reason = "invalid request.",
                        .timestamp = server.now(),
                    };

                    response.setResponseObjectOrInvalidate(report);
                    return try client.sendMessage(response.serialize() catch unreachable);
                },
            }
        },
    }

    return false;
}

fn handleHandshakeRequestDisconnected(server: *Server, client: *Client, request: *Protocol.Request(.handshake)) !bool {
    std.debug.assert(client.state == .connected);

    var simulation = server.simulation;
    const handshake: Protocol.Handshake.Request = try request.deserialize();
    const identity = simulation.whoIs(handshake.client_id);
    const client_is_registerd = simulation.internal.isRegistered(identity);

    if (client_is_registerd) {
        var response = client.getHandshakeResponse();
        defer response.deinit();

        const validation: Protocol.Handshake.Response = .{
            .token = 1,
            .status = true,
            .timestamp = server.now(),
        };

        response.setResponseObjectOrInvalidate(validation);
        client.transition(.connected);
        return try client.sendMessage(response.serialize() catch unreachable);
    } else {
        var response = client.getFailureResponse();

        const report: Protocol.Failure = .{
            .from = .handshake,
            .reason = "Not registered.",
            .timestamp = server.now(),
        };

        client.transition(.disconnected);
        response.setResponseObjectOrInvalidate(report);
        return try client.sendMessage(response.serialize() catch unreachable);
    }

    return false;
}

fn handleConfigRequest(server: *Server, client: *Client, _: *Protocol.Request(.config)) !bool {
    std.debug.assert(client.state == .connected);

    defer switch (client.state) {
        .authentificated => client.transition(.waiting),
        else => {},
    };

    var response = client.getConfigResponse();
    defer response.deinit();

    const config: Protocol.Config.Response = .{
        .status = true,
        .state = server.simulation.state,
        .timestamp = server.now(),
    };
    response.setResponseObjectOrInvalidate(config);
    return try client.sendMessage(response.serialize() catch unreachable);
}

fn handleUpdateRequest(server: *Server, client: *Client, request: *Protocol.Request(.update)) !bool {
    var simulation = server.simulation;

    const update: Protocol.Update.Request = try request.deserialize();
    if (simulation.internal.registerInput(simulation.internal.id(update.token_id), update.event)) {
        var response = client.getUpdateResponse();
        defer response.deinit();

        const answer: Protocol.Update.Response = .{
            .state = simulation.tick(),
            .timestamp = server.now(),
        };
        response.setResponseObjectOrInvalidate(answer);
        return try client.sendMessage(response.serialize() catch unreachable);
    } else {
        var response = client.getUpdateResponse();
        defer response.deinit();

        const answer: Protocol.Update.Response = .{
            .state = simulation.state,
            .timestamp = server.now(),
        };
        response.setResponseObjectOrInvalidate(answer);
        return try client.sendMessage(response.serialize() catch unreachable);
    }
}

fn handleAcknowledgementRequest(server: *Server, client: *Client, request: *Protocol.Request(.acknowledgement)) !bool {
    _ = server;
    _ = client;
    _ = request;
    return false;
}

fn handleFailureRequest(server: *Server, client: *Client, request: Protocol.Request(.failure)) !bool {
    _ = server;
    _ = client;
    _ = request;
    return false;
}

fn removeClient(self: *Server, client: *Client) void {
    const client_index = self.getClientIndex(client) orelse return;
    const pollfd_index = self.getPollfdIndex(client) orelse return;

    _ = self.clients.swapRemove(client_index);
    _ = self.pollfds.swapRemove(pollfd_index);

    client.deinit();
}

fn getClientBySocket(self: *Server, socket: posix.socket_t) ?*Client {
    return for (self.clients.items) |*client| {
        if (client.socket == socket) return client;
    } else null;
}

fn getClientIndex(self: *Server, client: *Client) ?usize {
    return for (self.clients.items, 0..) |item, idx| {
        if (item.socket == client.socket) return idx;
    } else null;
}

fn getPollfdIndex(self: *Server, client: *Client) ?usize {
    return for (self.pollfds.items, 0..) |pollfd, idx| {
        if (pollfd.fd == client.socket) return idx;
    } else null;
}

fn compare(s1: []const u8, s2: []const u8) bool {
    return mem.eql(u8, s1, s2);
}

fn now(_: *const Server) i64 {
    return time.milliTimestamp();
}
