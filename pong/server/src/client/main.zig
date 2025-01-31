// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   main.zig                                           :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/27 10:46:13 by pollivie          #+#    #+#             //
//   Updated: 2025/01/27 10:46:13 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const lib = @import("libpong");
const rl = @import("raylib");
const Pong = @import("Pong.zig");
const process = std.process;
const heap = std.heap;
const mem = std.mem;
const net = std.net;
const cli = lib.cli;
const log = std.log;

pub fn main() !void {
    var gpa: heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();

    log.info("Initializing client...", .{});
    var argv = try process.argsWithAllocator(gpa.allocator());
    defer argv.deinit();

    const params: cli.CliFlags = cli.parseCliFlags(&argv);
    log.info("Parsed client parameters: {any}", .{params});

    const address = net.Address.parseIp(params.ip, params.port) catch |err| {
        log.err("Failed to parse IP address {s}:{d}: {any}", .{ params.ip, params.port, err });
        return;
    };
    log.info("Parsed server address successfully: {any}", .{address});

    var stream = net.tcpConnectToAddress(address) catch |err| {
        log.err("Failed to connect to server at {any}: {any}", .{ address, err });
        return;
    };
    defer stream.close();
    log.info("Connected to server at {any}", .{address});

    var pong = Pong.init(gpa.allocator(), lib.State.init(params), address, stream.handle) catch |err| {
        log.err("Failed to initialize Pong client: {any}", .{err});
        return;
    };
    log.info("Pong client initialized successfully.", .{});

    rl.initWindow(
        pong.state.getBoard().dimension.width,
        pong.state.getBoard().dimension.height,
        "Pong",
    );
    defer rl.closeWindow();
    log.info("Initialized game window: {d}x{d}", .{
        pong.state.getBoard().dimension.width,
        pong.state.getBoard().dimension.height,
    });

    rl.setTargetFPS(1);
    log.info("Target FPS set to 1.", .{});

    log.info("Starting game loop with mode: {any}", .{pong.state.getKind()});
    switch (pong.state.getKind()) {
        .none => {
            testingAivsAi(&pong) catch |err| {
                log.err("AI vs AI testing failed: {any}", .{err});
                return;
            };
        },
        .local_ai => {
            localAiLoop(&pong) catch |err| {
                log.err("Local AI loop failed: {any}", .{err});
                return;
            };
        },
        .local_mp => {
            localMpLoop(&pong) catch |err| {
                log.err("Local multiplayer loop failed: {any}", .{err});
                return;
            };
        },
        .remote_mp => {
            remoteMpLoop(&pong) catch |err| {
                log.err("Remote multiplayer loop failed: {any}", .{err});
                return;
            };
        },
    }
    log.info("Game loop terminated.", .{});
}

fn testingAivsAi(pong: *Pong) !void {
    log.info("Starting AI vs AI testing loop.", .{});
    while (!rl.windowShouldClose()) {
        draw(pong);
    }
    log.info("AI vs AI testing loop terminated.", .{});
}

fn localAiLoop(pong: *Pong) !void {
    log.info("Starting local AI loop.", .{});
    var temp_state: lib.State = undefined;

    while (!rl.windowShouldClose()) {
        temp_state = pong.getInternalStateCopy();
        log.debug("Sending game state update to server.", .{});
        pong.sendUpdate(&temp_state) catch |err| {
            log.err("Failed to send game state update: {any}", .{err});
            return;
        };

        log.debug("Receiving game state update from server.", .{});
        pong.getUpdate(&temp_state) catch |err| {
            log.err("Failed to receive game state update: {any}", .{err});
            return;
        };

        log.debug("Updating internal game state.", .{});
        pong.updateInternalState(&temp_state);

        draw(pong);
    }
    log.info("Local AI loop terminated.", .{});
}

fn localMpLoop(pong: *Pong) !void {
    log.info("Starting local multiplayer loop.", .{});
    while (!rl.windowShouldClose()) {
        draw(pong);
    }
    log.info("Local multiplayer loop terminated.", .{});
}

fn remoteMpLoop(pong: *Pong) !void {
    log.info("Starting remote multiplayer loop.", .{});
    while (!rl.windowShouldClose()) {
        draw(pong);
    }
    log.info("Remote multiplayer loop terminated.", .{});
}

fn draw(pong: *Pong) void {
    rl.beginDrawing();
    log.debug("Drawing game elements.", .{});
    pong.drawBoard();
    pong.drawBall();
    pong.drawPaddles();
    rl.endDrawing();
    log.debug("Finished drawing game elements.", .{});
}
