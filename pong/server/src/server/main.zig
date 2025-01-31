// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   main.zig                                           :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/27 10:46:19 by pollivie          #+#    #+#             //
//   Updated: 2025/01/27 10:46:19 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const process = std.process;
const heap = std.heap;
const mem = std.mem;
const net = std.net;
const log = std.log;
const posix = std.posix;

const lib = @import("libpong");
const Message = lib.Message;
const cli = lib.cli;

const Client = @import("Client.zig");
const Server = @import("Server.zig");

pub fn main() !void {
    var gpa: heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();

    var argv = process.argsWithAllocator(gpa.allocator()) catch |err| {
        log.err("Initialization error: failed to allocate argv: {any}", .{err});
        return;
    };
    defer argv.deinit();
    const params: cli.CliFlags = cli.parseCliFlags(&argv);

    log.info("Parsed server parameters: IP={s}, Port={d}, Flags={any}", .{ params.ip, params.port, params });
    const address = net.Address.parseIp(params.ip, params.port) catch |err| {
        log.err("Address parsing failed for {s}:{d}: {any}", .{ params.ip, params.port, err });
        return;
    };

    var server = Server.init(gpa.allocator(), address, params) catch |err| {
        log.err("Server initialization failed: {any}", .{err});
        return;
    };
    defer server.deinit();

    log.info("Server initialized on {any}", .{server.addr});
    server.listen() catch |err| {
        log.err("Listening on {any} failed: {any}", .{ server.addr, err });
        return;
    };

    log.info("Server listening on {any}", .{server.addr});
    run(&server) catch |err| {
        log.err("Server runtime error: {any}", .{err});
        return;
    };
}

pub fn run(server: *Server) !void {
    log.info("Server running at {any}", .{server.addr});
    const addr = server.addr;

    var testing_state_bytes: []u8 = server.pong.ptr;

    while (true) {
        const pollfds = server.pollfds.items[0..];
        const npfds = posix.poll(pollfds, 500) catch |err| {
            log.err("Polling error at {any}: {any}", .{ addr, err });
            return err;
        };
        log.debug("Polled {d} events at {any}", .{ npfds, addr });

        if (pollfds[0].revents & posix.POLL.IN == posix.POLL.IN) {
            log.info("{any}: Connection request received.", .{addr});
            const new_client = server.accept() catch |err| {
                log.err("Failed to accept connection at {any}: {any}", .{ addr, err });
                switch (err) {
                    error.WouldBlock, error.ConnectionResetByPeer, error.ConnectionAborted => continue,
                    else => return err,
                }
            };
            log.info("New client connected: {any}, Address: {any}", .{ addr, new_client.addr });
            continue;
        }

        log.debug("Handling {d} client events at {any}", .{ (npfds -| 1), addr });
        for (pollfds[1..]) |*pfd| {
            if (pfd.revents == 0) continue;
            const client = server.getAssociatedClient(pfd.*) catch |err| {
                log.err("Error retrieving client associated with pollfd at {any}: {any}", .{ addr, err });
                continue;
            };
            log.debug("Client association successful: {any}, Address: {any}", .{ addr, client.addr });

            if (pfd.revents & posix.POLL.ERR == posix.POLL.ERR or pfd.revents & posix.POLL.HUP == posix.POLL.HUP) {
                log.info("Client disconnected: {any}, Address: {any}", .{ addr, client.addr });
                server.removeClient(client);
                break;
            }

            if (pfd.revents & posix.POLL.IN == posix.POLL.IN) {
                log.info("Reading message from client {any}, Address: {any}", .{ addr, client.addr });
                if (client.mode != .recv) {
                    log.warn("Client mode mismatch for reading: {any}, Address: {any}, Mode: {any}", .{ addr, client.addr, client.mode });
                }

                client.recv() catch |err| {
                    log.err("Error reading message from client {any}, Address: {any}: {any}", .{ addr, client.addr, err });
                    server.removeClient(client);
                    break;
                };
                client.mode = .send;
                pfd.events = posix.POLL.OUT;

                if (client.getRequest(testing_state_bytes[0..64])) {
                    log.info("Received client request: {any}, Message: {any}", .{ addr, server.pong.internal });
                } else {
                    log.warn("Failed to read client request at {any}", .{addr});
                }

                if (client.putResponse(testing_state_bytes[0..64])) {
                    log.info("Sent response to client: {any}, Message: {any}", .{ addr, server.pong.internal });
                } else {
                    log.warn("Failed to send response to client at {any}", .{addr});
                }
            }

            if (pfd.revents & posix.POLL.OUT == posix.POLL.OUT) {
                log.info("Writing message to client {any}, Address: {any}", .{ addr, client.addr });
                if (client.mode != .send) {
                    log.warn("Client mode mismatch for writing: {any}, Address: {any}, Mode: {any}", .{ addr, client.addr, client.mode });
                }

                client.send() catch |err| {
                    log.err("Error writing message to client {any}, Address: {any}: {any}", .{ addr, client.addr, err });
                    server.removeClient(client);
                    break;
                };
                client.mode = .recv;
                pfd.events = posix.POLL.IN;
            }
        }
    }
}
