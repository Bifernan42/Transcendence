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

const Ball = @import("Ball.zig");
const Board = @import("Board.zig");
const Client = @import("Client.zig");
const Paddle = @import("Paddle.zig");
const Player = @import("Player.zig");
const Pong = @import("Pong.zig");
const Server = @import("Server.zig");
const Config = @import("Config.zig");

pub fn main() !void {
    var gpa: heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();

    var config: Config = try .init(gpa.allocator());
    defer config.deinit();
    try config.parse();

    const address = net.Address.parseIp(config.serv_config.ip, config.serv_config.port) catch |err| {
        log.err("failed to parse requested address. : {!}", .{err});
        return;
    };

    var server = Server.init(gpa.allocator(), address, config.serv_config);
    defer server.deinit();

    try server.listen();

    try run(config, &server);
}

pub fn run(config: Config, server: *Server) !void {
    log.info("Server running at {any}", .{server});
    var pong: Pong = .init(config.pong_config);

    if (server.options.headless == true) {
        while (true) {
            try handleNetwork(server, &pong);
        }
    } else {
        rl.initWindow(@intCast(config.pong_config.board_width), @intCast(config.pong_config.board_height), "Pong Server");
        rl.setTargetFPS(0);
        // rl.setTargetFPS(config.serv_config.tickrate);
        while (!rl.windowShouldClose()) {
            try handleNetwork(server, &pong);

            rl.beginDrawing();
            defer rl.endDrawing();
            pong.pong.drawBoard(128, 2.0, rl.Color.white, rl.Color.black);
            pong.pong.drawPaddles(4, rl.Color.white, rl.Color.orange);
            pong.pong.drawBall(2, rl.Color.white, rl.Color.orange);
            rl.drawFPS(20, 20);
        }
    }
}

pub fn handleNetwork(server: *Server, pong: *Pong) !void {
    const pollfds = server.pollfds.items[0..];
    const npfds = posix.poll(pollfds, 1) catch |err| {
        log.err("Polling error at {any}: {any}", .{ server, err });
        return err;
    };
    log.debug("Polled {d} events at {any}", .{ npfds, server });

    if (pollfds[0].revents & posix.POLL.IN == posix.POLL.IN) {
        log.info("{any}: Connection request received.", .{server});
        const new_client = server.accept() catch |err| {
            log.err("Failed to accept connection at {any}: {any}", .{ server, err });
            switch (err) {
                error.WouldBlock, error.ConnectionResetByPeer, error.ConnectionAborted => return,
                else => return err,
            }
        };
        log.info("New client connected: {any}, Address: {any}", .{ server, new_client });
        return;
    }

    log.debug("Handling {d} client events at {any}", .{ (npfds -| 1), server });
    for (pollfds[1..]) |*pfd| {
        if (pfd.revents == 0) continue;
        const client = server.getAssociatedClient(pfd.*) catch |err| {
            log.err("Error retrieving client associated with pollfd at {any}: {any}", .{ server, err });
            return;
        };

        if (pfd.revents & posix.POLL.ERR == posix.POLL.ERR or pfd.revents & posix.POLL.HUP == posix.POLL.HUP) {
            log.info("Client disconnected: {any}, Address: {any}", .{ server, client });
            server.removeClient(client);
            return;
        }

        if (pfd.revents & posix.POLL.IN == posix.POLL.IN) {
            log.info("Reading message from client {any}, Address: {any}", .{ server, client });
            var request: lib.Request = .{};
            try client.readRequest(&request);
            log.info("{} sent {}", .{ client, request });
            pfd.events = posix.POLL.OUT;
        }

        if (pfd.revents & posix.POLL.OUT == posix.POLL.OUT) {
            var response: lib.Response = .init(lib.Response{
                .screen_height = @intFromFloat(pong.board.board.dimension.height),
                .screen_width = @intFromFloat(pong.board.board.dimension.width),
                .ball_position_x = pong.ball.ball.position.x,
                .ball_position_y = pong.ball.ball.position.y,
                .paddle_height = @intFromFloat(pong.player1.player.paddle.dimension.height),
                .paddle_width = @intFromFloat(pong.player1.player.paddle.dimension.width),
                .ball_radius = pong.ball.ball.radius,
                .player1_paddle_x = pong.player1.player.paddle.dimension.x,
                .player1_paddle_y = pong.player1.player.paddle.dimension.y,
                .player2_paddle_x = pong.player2.player.paddle.dimension.x,
                .player2_paddle_y = pong.player2.player.paddle.dimension.y,
                .player1_score = pong.player1.score,
                .player2_score = pong.player2.score,
                .status = .lobby,
                .timestamp = std.time.timestamp(),
                ._padding = 0,
            });
            try client.sendResponse(&response);
            pfd.events = posix.POLL.IN;
        }
    }
}
