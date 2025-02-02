// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   main.zig                                           :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/30 10:09:28 by pollivie          #+#    #+#             //
//   Updated: 2025/01/30 10:09:29 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const process = std.process;
const heap = std.heap;
const mem = std.mem;
const net = std.net;
const log = std.log;
const posix = std.posix;

const rg = @import("raygui");
const rl = @import("raylib");

const lib = @import("libpong");
const Request = lib.Request;
const Response = lib.Response;

const Pong = lib.Pong;
const Config = lib.Config;
const Client = @import("Client.zig").Client;
const Server = @import("Server.zig").Server;
const PongOptions = Config.PongOptions;

pub fn main() !void {
    var gpa: heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();

    var config = Config.init(gpa.allocator()) catch |err| {
        log.err("fatal error encountered, shutting down : {!}", .{err});
        return;
    };
    defer config.deinit();

    const options: PongOptions = config.parseEnviromentVariables();

    const address = net.Address.parseIp(options.server_ip, options.server_port) catch |err| {
        log.err("fatal error encountered, shutting down : {!}", .{err});
        return;
    };

    var server = Server.init(gpa.allocator(), address, options) catch |err| {
        log.err("fatal error encountered, shutting down : {!}", .{err});
        return;
    };
    defer server.deinit();

    server.listen() catch |err| {
        log.err("fatal error encountered, shutting down : {!}", .{err});
        return;
    };

    switch (options.server_headless) {
        true => runHeadless(&server, options) catch |err| {
            log.err("fatal error encountered, shutting down : {!}", .{err});
            return;
        },
        false => runWithHead(&server, options) catch |err| {
            log.err("fatal error encountered, shutting down : {!}", .{err});
            return;
        },
    }
}

pub fn runWithHead(server: *Server, options: Config.PongOptions) !void {
    log.info("{} running...", .{server});
    rl.initWindow(server.options.board_width, server.options.board_height, "Pong Server");
    defer rl.closeWindow();
    rl.setTargetFPS(options.server_tickrate);
    while (!rl.windowShouldClose()) {
        try sendAndFetchPongEvents(server, &server.pong);
        renderPongEvents(&server.pong);
    }
}

pub fn runHeadless(server: *Server, options: Config.PongOptions) !void {
    log.info("{} running...", .{server});
    var pong: Pong = Pong.init(options);
    while (true) {
        try sendAndFetchPongEvents(server, &pong);
    }
}

pub fn renderPongEvents(pong: *const lib.Pong) void {
    rl.beginDrawing();
    rl.clearBackground(rl.Color.black);
    pong.drawBoard(128, 4.0, rl.Color.gold, rl.Color.dark_gray);
    pong.drawPaddles(4.0, rl.Color.red, rl.Color.orange);
    pong.drawBall(2.0, rl.Color.green, rl.Color.dark_green);
    rl.drawFPS(20, 20);
    rl.endDrawing();
}

pub fn sendAndFetchPongEvents(server: *Server, pong: *Pong) !void {
    const pollfds = server.pollfds.items[0..];

    const npfds = posix.poll(pollfds, 0) catch |err| {
        log.err("{} poll failed with {!}", .{ server, err });
        return err;
    };

    if (npfds == 0) {
        return;
    }

    if (pollfds[0].revents & posix.POLL.IN == posix.POLL.IN) {
        log.info("{} has one pending connection request.", .{server});
        const new_client = server.accept() catch |err| {
            log.err("{} failed to accept connection request. reason : {!}", .{ server, err });
            switch (err) {
                error.WouldBlock, error.ConnectionResetByPeer, error.ConnectionAborted => return,
                else => return err,
            }
        };
        log.info("{} connected new client {}.", .{ server, new_client });
        return;
    }

    log.debug("{} handling events for {d} client events.", .{ server, (npfds -| 1) });
    for (pollfds[1..]) |*pfd| {
        if (pfd.revents == 0) continue;
        const client = server.getAssociatedClient(pfd.*) catch |err| {
            log.err("{} failed to find matching client. reason : {!}", .{ server, err });
            return;
        };

        if (pfd.revents & posix.POLL.ERR == posix.POLL.ERR or pfd.revents & posix.POLL.HUP == posix.POLL.HUP) {
            log.info("{} need to disconnect {}", .{ server, client });
            server.removeClient(client);
            return;
        } else if (pfd.revents & posix.POLL.IN == posix.POLL.IN) {
            var request: lib.Request = lib.Request.init();
            client.readRequest(&request) catch |err| {
                log.err("{} while reading request to {} got : {!}", .{ server, client, err });
                server.removeClient(client);
                return;
            };
            log.info("{} received {} from {}", .{ server, request, client });
            pfd.events = posix.POLL.OUT;
            pong.processRequest(&request);
            var response = pong.serialize();
            client.response.fromBytes(response.asBytes());
        } else if (pfd.revents & posix.POLL.OUT == posix.POLL.OUT) {
            const response = &client.response;
            log.info("{} sending {} to {}", .{ server, response, client });
            client.sendResponse(response) catch |err| {
                log.err("{} while sending response to {} got : {!}", .{ server, client, err });
                server.removeClient(client);
                return;
            };
            pfd.events = posix.POLL.IN;
        }
    }
}
