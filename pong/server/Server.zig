// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Server.zig                                         :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/30 14:39:57 by pollivie          #+#    #+#             //
//   Updated: 2025/01/30 14:39:57 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const log = std.log;
const net = std.net;
const mem = std.mem;
const posix = std.posix;
const Buffer = std.ArrayListUnmanaged;
const RingBuffer = std.RingBuffer;
const lib = @import("libpong");
const rg = @import("raygui");
const rl = @import("raylib");
const Client = @import("Client.zig").Client;
const Pong = lib.Pong;
const Config = lib.Config;
const PongOptions = Config.PongOptions;

pub const Server = struct {
    options: Config.PongOptions,
    pong: Pong,
    allocator: mem.Allocator,
    address: net.Address,
    socket: posix.socket_t,
    clients: Buffer(Client),
    pollfds: Buffer(posix.pollfd),

    pub fn init(allocator: mem.Allocator, address: net.Address, options: Config.PongOptions) error{OutOfMemory}!Server {
        return .{
            .options = options,
            .pong = Pong.init(options),
            .allocator = allocator,
            .socket = -1,
            .address = address,
            .clients = try Buffer(Client).initCapacity(allocator, options.server_client_max),
            .pollfds = try Buffer(posix.pollfd).initCapacity(allocator, options.server_client_max),
        };
    }

    pub fn deinit(self: *Server) void {
        for (self.clients.items) |*client| {
            client.deinit();
        }
        self.pollfds.deinit(self.allocator);
        self.clients.deinit(self.allocator);
        if (self.socket != -1) {
            posix.close(self.socket);
        }
        self.* = undefined;
    }

    pub fn listen(self: *Server) !void {
        const socket = posix.socket(
            self.address.any.family,
            posix.SOCK.STREAM | posix.SOCK.NONBLOCK,
            posix.IPPROTO.TCP,
        ) catch |err| {
            log.err("{any} :: failed to open socket: {any}", .{ self, err });
            return err;
        };
        errdefer posix.close(socket);

        posix.setsockopt(
            socket,
            posix.SOL.SOCKET,
            posix.SO.REUSEADDR | posix.SO.REUSEPORT,
            &mem.toBytes(@as(c_int, 1)),
        ) catch |err| {
            log.err("{any} :: failed to configure socket: {any}", .{ self, err });
            return err;
        };

        posix.bind(
            socket,
            &self.address.any,
            self.address.getOsSockLen(),
        ) catch |err| {
            log.err("{any} :: failed to bind socket: {any}", .{ self, err });
            return err;
        };

        posix.listen(
            socket,
            4,
        ) catch |err| {
            log.err("{any} :: failed to listen on socket: {any}", .{ self, err });
            return err;
        };

        self.socket = socket;

        const server_poll: posix.pollfd = .{
            .fd = self.socket,
            .events = posix.POLL.IN,
            .revents = 0,
        };

        self.pollfds.append(self.allocator, server_poll) catch |err| {
            log.err("{any} :: failed to append server pollfd: {any}", .{ self, err });
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
            log.err("{any} :: failed to accept client: {any}", .{ self, err });
            return err;
        };

        const client = Client.init(address, socket);

        const client_poll: posix.pollfd = .{
            .fd = client.socket,
            .events = posix.POLL.IN,
            .revents = 0,
        };

        self.pollfds.append(self.allocator, client_poll) catch |err| {
            log.err("{any} :: failed to append client pollfd: {any}", .{ self, err });
            return err;
        };

        self.clients.append(self.allocator, client) catch |err| {
            log.err("{any} :: failed to append client {any} : {any}", .{ self, client, err });
            return err;
        };

        return client;
    }

    pub fn getAssociatedClient(self: *const Server, pollfd: posix.pollfd) !*Client {
        for (self.clients.items) |*client| {
            if (client.socket == pollfd.fd) {
                return client;
            }
        }
        return error.NotFound;
    }

    pub fn removeClient(self: *Server, client: *Client) void {
        for (self.clients.items, 0..) |maybe_client, i| {
            if (maybe_client.socket == client.socket) {
                _ = self.clients.swapRemove(i);
                break;
            }
        }

        for (self.pollfds.items, 0..) |pfd, i| {
            if (pfd.fd == client.socket) {
                _ = self.pollfds.swapRemove(i);
                break;
            }
        }
        client.deinit();
    }

    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("{}", .{self.address});
    }
};
