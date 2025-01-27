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
const cli = lib.cli;

pub fn main() !void {
    var gpa: heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();

    var argv = process.argsWithAllocator(gpa.allocator()) catch |err| {
        log.err("failure to initialize argv : {!}", .{err});
        return;
    };
    defer argv.deinit();
    const params: cli.CliFlags = cli.parseCliFlags(&argv);

    log.debug("{s}:{d} :: server parameters parsed :: {any}", .{ params.ip, params.port, params });
    const address = net.Address.parseIp(params.ip, params.port) catch |err| {
        log.err("{s}:{d} :: failed to parse configured address :: {!}", .{ params.ip, params.port, err });
        return;
    };

    var server = lib.Server.init(gpa.allocator(), address, params) catch |err| {
        log.err("failed to initialize server : {!}", .{err});
        return;
    };
    defer server.deinit();

    log.debug("{} :: server initialized", .{server.addr});
    server.listen() catch |err| {
        log.err("{} :: failed to listen with server :: {!}", .{ server.addr, err });
        return;
    };

    log.debug("{} :: server listening...", .{server.addr});
    run(&server) catch |err| {
        log.err("failed to listen with server :: {!}", .{err});
        return;
    };
}

pub fn run(server: *lib.Server) !void {
    log.debug("{} :: server running...", .{server.addr});
    const addr = server.addr;

    var testing_state: lib.Message = .zero;
    var testing_state_bytes = mem.asBytes(&testing_state).*;

    while (true) {
        const pollfds = server.pollfds.items[0..];
        const npfds = posix.poll(pollfds, 0) catch |err| {
            log.err("{} :: server failed to poll :: {!}", .{ addr, err });
            return err;
        };
        log.debug("{} :: total events polled {d}", .{ addr, npfds });

        if (pollfds[0].revents & posix.POLL.IN == posix.POLL.IN) {
            log.debug("{} :: server received a connection request.", .{addr});
            const new_client = server.accept() catch |err| {
                log.err("{} :: server failed to accept incoming connection :: {!}", .{ addr, err });
                switch (err) {
                    error.WouldBlock, error.ConnectionResetByPeer, error.ConnectionAborted => continue,
                    else => return err,
                }
            };
            log.debug("{} :: server successfuly accepted new client {}", .{ addr, new_client.addr });
            log.debug("{} :: server configured client to notify when ready to read :: POLL.IN", .{addr});
            continue;
        }

        log.debug("{} :: handling remaining client events {d}", .{ addr, (npfds -| 1) });
        for (pollfds[1..]) |*pfd| {
            if (pfd.revents == 0) continue;
            const client = server.getAssociatedClient(pfd.*) catch |err| {
                std.log.err("{} :: internal server error :: {!}", .{ addr, err });
                continue;
            };
            log.debug("{} :: succesfully found associated client. {}", .{ addr, client.addr });

            if (pfd.revents & posix.POLL.ERR == posix.POLL.ERR or pfd.revents & posix.POLL.HUP == posix.POLL.HUP) {
                log.debug("{} :: poll signaled that client closed connection {}", .{ addr, client.addr });
                server.removeClient(client);
                break;
            }

            if (pfd.revents & posix.POLL.IN == posix.POLL.IN) {
                log.debug("{} :: client's sent a message to read. {}", .{ addr, client.addr });
                if (client.mode != .recv) {
                    log.warn("{} :: internal warning, client's mode isn't appropriate for current poll flag {}", .{ addr, client.addr });
                }
                log.debug("{} :: attempting to read client's message", .{addr});

                client.recv() catch |err| {
                    std.log.err("{} :: internal server error :: {!}", .{ addr, err });
                    server.removeClient(client);
                    break;
                };
                client.mode = .send;
                pfd.events ^= pfd.events;
                pfd.events = posix.POLL.OUT;

                if (client.getRequest(&testing_state_bytes)) {
                    log.debug("{} :: received client's request :: {}", .{ addr, testing_state });
                } else {
                    log.debug("{} :: failled to receive client update.", .{addr});
                }

                if (client.putResponse(&testing_state_bytes)) {
                    log.debug("{} :: sending response :: {}", .{ addr, testing_state });
                } else {
                    log.debug("{} :: failled to put response", .{addr});
                }
            }

            if (pfd.revents & posix.POLL.OUT == posix.POLL.OUT) {
                log.debug("{} :: client's sent a message to write. {}", .{ addr, client.addr });
                if (client.mode != .send) {
                    log.warn("{} :: internal warning, client's mode isn't appropriate for current poll flag {}", .{ addr, client.addr });
                }
                log.debug("{} :: attempting to write client's message", .{addr});

                client.send() catch |err| {
                    std.log.err("{} :: internal server error :: {!}", .{ addr, err });
                    server.removeClient(client);
                    break;
                };
                client.mode = .recv;
                pfd.events ^= pfd.events;
                pfd.events = posix.POLL.IN;
            }
        }
    }
}
