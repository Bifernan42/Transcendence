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
const Protocol = @import("Protocol.zig");
const Client = @import("Client.zig");
const Config = @import("Config.zig");
const String = @import("String.zig").String;
const Server = @This();

gpa: std.mem.Allocator,
config: Config,
socket: posix.socket_t,
clients: std.ArrayListUnmanaged(Client),
pollfds: std.ArrayListUnmanaged(posix.pollfd),
request_arena: std.heap.ArenaAllocator,
response_arena: std.heap.ArenaAllocator,

pub fn init(gpa: std.mem.Allocator, config: Config) !Server {
    var request_arena = std.heap.ArenaAllocator.init(gpa);
    errdefer request_arena.deinit();

    var response_arena = std.heap.ArenaAllocator.init(gpa);
    errdefer response_arena.deinit();

    const address = try net.Address.parseIp(config.ip, config.port);
    const socket = try createSocket(address);
    errdefer posix.close(socket);

    return .{
        .gpa = gpa,
        .config = config,
        .socket = socket,
        .clients = .empty,
        .pollfds = .empty,
        .request_arena = request_arena,
        .response_arena = response_arena,
    };
}

pub fn deinit(self: *Server) void {
    if (self.socket != -1) {
        posix.close(self.socket);
    }
    self.request_arena.deinit();
    self.response_arena.deinit();
}

fn createSocket(address: net.Address) !posix.socket_t {
    const socket = try posix.socket(address.any.family, posix.SOCK.STREAM | posix.SOCK.NONBLOCK, posix.IPPROTO.TCP);

    try posix.setsockopt(
        socket,
        posix.SOL.SOCKET,
        posix.SO.REUSEADDR,
        &std.mem.toBytes(@as(c_int, 1)),
    );

    try posix.bind(socket, &address.any, address.getOsSockLen());
    try posix.listen(socket, 10);

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

    const client_socket = try posix.accept(self.socket, &client_addr.any, &socklen, posix.SOCK.NONBLOCK);

    var client = try Client.init(self.gpa, client_addr, client_socket);
    errdefer client.deinit();

    try self.clients.append(self.gpa, client);
    try self.pollfds.append(self.gpa, .{
        .fd = client_socket,
        .events = posix.POLL.IN,
        .revents = 0,
    });
}

fn handleClientRequest(self: *Server, client: *Client) !void {
    const allocator = self.request_arena.allocator();
    defer _ = self.request_arena.reset(.retain_capacity);

    const message = try client.getMessage(allocator) orelse return;

    if (message.len == 0) {
        log.info("Empty message received, closing connection.", .{});
        self.removeClient(client);
        return;
    } else {
        log.info("Received message from client : '{s}'", .{message});
    }

    const parsed_request = try json.parseFromSlice(Protocol.Handshake.Request, allocator, message, .{});
    try self.processRequest(client, parsed_request.value);
}

fn processRequest(self: *Server, client: *Client, request: Protocol.Handshake.Request) !void {
    const response: Protocol.Handshake.Response = .{
        .status = true,
        .timestamp = time.milliTimestamp(),
        .token = std.hash.int(@abs(request.timestamp) + request.client_id.len),
    };

    const allocator = self.response_arena.allocator();
    defer _ = self.response_arena.reset(.retain_capacity);

    const response_data = try json.stringifyAlloc(allocator, response, .{});
    var response_builder: String = try String.initCapacity(allocator, response_data.len * 2);

    try response_builder.insertSliceFront(response_data);
    try response_builder.insertSliceBack(Protocol.Delimiter);

    try self.sendResponse(client, response_builder.data());
}

fn sendResponse(server: *Server, client: *Client, response: []const u8) !void {
    _ = server;
    var total_sent: usize = 0;
    log.info("Sending response to client : '{s}'", .{response});
    while (total_sent < response.len) {
        const bytes_sent = posix.send(client.socket, response[total_sent..], 0) catch |err| {
            log.err("Error sending response to client. {!}", .{err});
            return err;
        };
        total_sent += bytes_sent;
        log.info("total_sent {d}.", .{total_sent});
    }
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
