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
pub const std_options: std.Options = .{
    .log_level = .info,
};

const Client = @import("Client.zig");
const Config = @import("Config.zig");
const Pong = @import("Pong.zig");
const Protocol = @import("Protocol.zig");
const Server = @This();

gpa: mem.Allocator,
config: Config,
address: net.Address,
socket: posix.socket_t,
pollfds: std.ArrayListUnmanaged(posix.pollfd),
clients: std.ArrayListUnmanaged(Client),
request_arena: heap.ArenaAllocator,
response_arena: heap.ArenaAllocator,

pub fn init(gpa: mem.Allocator, config: Config) !Server {
    var request_arena: heap.ArenaAllocator = .init(gpa);
    errdefer request_arena.deinit();
    var response_arena: heap.ArenaAllocator = .init(gpa);
    errdefer response_arena.deinit();

    var address: net.Address = try .parseIp(config.ip, config.port);

    const socket = posix.socket(address.any.family, posix.SOCK.STREAM | posix.SOCK.NONBLOCK, posix.IPPROTO.TCP) catch |err| {
        log.err("socket failed. {!}", .{err});
        return err;
    };
    errdefer posix.close(socket);

    posix.setsockopt(socket, posix.SOL.SOCKET, posix.SO.REUSEADDR | posix.SO.REUSEPORT, &mem.toBytes(@as(c_int, 0))) catch |err| {
        log.err("setsockopt failed. {!}", .{err});
        return err;
    };

    posix.bind(socket, &address.any, address.getOsSockLen()) catch |err| {
        log.err("bind failed. {!}", .{err});
        return err;
    };

    posix.listen(socket, 4) catch |err| {
        log.err("bind failed. {!}", .{err});
        return err;
    };

    return .{
        .gpa = gpa,
        .config = config,
        .address = address,
        .socket = socket,
        .pollfds = std.ArrayListUnmanaged(posix.pollfd).empty,
        .clients = std.ArrayListUnmanaged(Client).empty,
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

var should_stop: bool = false;

fn signalHandler(signal: i32) callconv(.c) void {
    log.debug("signal received {d}, shutting down...", .{signal});
    should_stop = true;
}

fn setupSignalHandling(_: *const Server) void {
    var sa: posix.Sigaction = .{
        .handler = .{ .handler = signalHandler },
        .mask = posix.empty_sigset,
        .flags = posix.SA.RESETHAND,
    };

    posix.sigaction(posix.SIG.INT, &sa, null);
}

pub fn run(server: *Server) !void {
    const sleep_nano: u64 = @divTrunc(time.ns_per_s, @as(u64, server.config.tickrate));

    if (builtin.mode != .Debug) {
        server.setupSignalHandling();
    }

    try server.pollfds.append(server.gpa, .{
        .fd = server.socket,
        .events = posix.POLL.IN,
        .revents = 0,
    });

    while (!should_stop) {
        log.info("{} waiting for events...", .{server.address});
        server.tick() catch |err| {
            switch (err) {
                else => {
                    log.err("tick failed with {!}.", .{err});
                },
            }
        };
        posix.nanosleep(0, sleep_nano);
    }
}

pub fn tick(server: *Server) !void {
    const address = server.address;
    const pollfds = server.pollfds.items;
    _ = try posix.poll(pollfds, 0);

    for (pollfds) |polled| {
        if (polled.fd == server.socket and polled.revents != 0) {
            server.acceptClient() catch |err| {
                log.err("{} failed to accept client. {!}", .{ address, err });
                continue;
            };
            break;
        }

        var client = server.getClientFromFd(polled.fd) orelse continue;
        if (polled.revents & posix.POLL.IN == posix.POLL.IN) {
            server.handleClientRequest(&client) catch |err| {
                log.err("{} closing client. {}:{!}", .{ address, client.address, err });
                server.removeClient(&client);
                break;
            };
        } else if (polled.revents & posix.POLL.OUT == posix.POLL.OUT) {
            server.sendResponse(client) catch |err| {
                log.err("{} closing client. {}:{!}", .{ address, client.address, err });
                server.removeClient(&client);
                break;
            };
        }
    }
}

pub fn acceptClient(server: *Server) !void {
    var address: net.Address = undefined;
    var socklen: posix.socklen_t = @sizeOf(net.Address);

    const client_socket = try posix.accept(server.socket, &address.any, &socklen, posix.SOCK.NONBLOCK);
    errdefer posix.close(client_socket);

    var client = try Client.init(server.gpa, address, client_socket);
    errdefer client.deinit();

    try server.pollfds.resize(server.gpa, server.pollfds.capacity + 1);
    try server.clients.resize(server.gpa, server.clients.capacity + 1);

    server.pollfds.appendAssumeCapacity(client.getPollIn());
    server.clients.appendAssumeCapacity(client);
}

pub fn removeClient(server: *Server, client: *Client) void {
    const pollfd_index = server.getPollfdIndex(client.*) orelse return;
    const client_index = server.getClientIndex(client.*) orelse return;
    defer _ = server.pollfds.swapRemove(pollfd_index);
    defer _ = server.clients.swapRemove(client_index);
    client.deinit();
}

pub fn handleClientRequest(server: *Server, client: *Client) !void {
    const request_arena = server.request_arena.allocator();
    defer _ = server.request_arena.reset(.retain_capacity);
    const maybe_message = try client.getMessage(request_arena);

    if (maybe_message) |message| {
        std.debug.print("{} sent : '{s}'\n", .{ server.address, message });
    } else {
        std.debug.print("{} sent : '{s}'\n", .{ server.address, "" });
    }
}

pub fn sendResponse(server: *Server, client: Client) !void {
    _ = server;
    _ = client;
}

pub fn getClientFromFd(server: *const Server, client_socket: i32) ?Client {
    return for (server.clients.items) |client| {
        if (client.socket == client_socket) return client;
    } else null;
}

fn getPollfdIndex(server: *const Server, client: Client) ?usize {
    return for (server.pollfds.items, 0..) |item, index| {
        if (item.fd == client.socket) return index;
    } else null;
}

fn getClientIndex(server: *const Server, client: Client) ?usize {
    return for (server.clients.items, 0..) |item, index| {
        if (item.socket == client.socket) return index;
    } else null;
}
