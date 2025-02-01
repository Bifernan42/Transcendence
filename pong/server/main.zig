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

const Pong = @import("Pong.zig");
const Config = @import("Config.zig");
const Client = @import("Client.zig").Client;
const Server = @import("Server.zig").Server;

pub fn main() !void {
    var gpa: heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();

    var config = Config.init(gpa.allocator()) catch |err| {
        log.err("fatal error encountered, shutting down : {!}", .{err});
        return;
    };
    defer config.deinit();

    const options: Pong.PongOptions = config.parseEnviromentVariables();

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

var timeout: i32 = 0;

pub fn runWithHead(server: *Server, options: Pong.PongOptions) !void {
    log.info("{} running...", .{server});
    rl.initWindow(server.pong.board_width, server.pong.board_height, "Pong Server");
    defer rl.closeWindow();
    rl.setTargetFPS(options.server_tickrate);
    timeout = std.time.ms_per_s * (server.options.server_tickrate);
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();
        server.pong.draw(.{});
        try handleNetwork(server, &server.pong);
        rl.drawFPS(20, 20);
    }
}

pub fn runHeadless(server: *Server, options: Pong.PongOptions) !void {
    log.info("{} running...", .{server});
    var pong: Pong.Pong = Pong.Pong.init(options);
    while (true) {
        try handleNetwork(server, &pong);
    }
}

pub fn handleNetwork(server: *Server, pong: *Pong) !void {
    const pollfds = server.pollfds.items[0..];
    const npfds = posix.poll(pollfds, timeout) catch |err| {
        log.err("{} poll failed with {!}", .{ server, err });
        return err;
    };
    if (npfds == 0) return;
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
            handleRequest(server, client, &request);
        } else if (pfd.revents & posix.POLL.OUT == posix.POLL.OUT) {
            @branchHint(.likely);
            var response = pong.play();
            log.info("{} sending {} to {}", .{ server, response, client });
            client.sendResponse(&response) catch |err| {
                log.err("{} while sending response to {} got : {!}", .{ server, client, err });
                server.removeClient(client);
                return;
            };
            pfd.events = posix.POLL.IN;
        }
    }
}

pub fn handleRequest(server: *Server, client: *Client, request: *lib.Request) void {
    if (client.id) |known_client_id| {
        @branchHint(.likely);
        handleRequestFromKnownClient(server, known_client_id, request);
    } else {
        @branchHint(.cold);
        if (request.client_id == server.options.player1_token) { // player1 first connection
            client.*.id = server.options.player1_token;
            server.pong.player1_status = .ready;
        } else if (request.client_id == server.options.player2_token) { // player2 first connection
            client.*.id = server.options.player2_token;
            server.pong.player2_status = .ready;
        } else { // random spectator
            var rand = std.Random.DefaultPrng.init(@abs(request.timestamp));
            client.*.id = @as(u32, @truncate(rand.next()));
        }
        handleRequestFromKnownClient(server, client.id orelse 0, request);
    }
}

pub fn handleRequestFromKnownClient(server: *Server, id: u32, request: *lib.Request) void {
    switch (server.options.getRole(id)) {
        .player1 => {
            server.pong.player1_move = request.player1_action;
            server.pong.player1_status = .ready;
        },
        .player2 => {
            server.pong.player2_move = request.player2_action;
            server.pong.player1_status = .ready;
        },
        else => return,
    }
}
