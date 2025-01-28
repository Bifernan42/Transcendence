// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Pong.zig                                           :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/28 11:47:29 by pollivie          #+#    #+#             //
//   Updated: 2025/01/28 11:47:30 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const builtin = @import("builtin");
const net = std.net;
const posix = std.posix;
const std = @import("std");
const log = std.log;
const lib = @import("libpong");
const rl = @import("raylib");
const Player = @import("Player.zig");
const Paddle = @import("Paddle.zig");
const Ball = @import("Ball.zig");
const Board = @import("Board.zig");
const mem = std.mem;
const heap = std.heap;
const Pong = @This();
const PongServer = @import("PongServer.zig");

gpa: mem.Allocator,
state: lib.State,
server: PongServer,
player1: Player,
player2: Player,
board: Board,
ball: Ball,

pub const PongState = enum {
    playing,
    paused,
    finished,
};

pub const PongError = error{
    InvalidState,
};

pub fn init(gpa: mem.Allocator, state: lib.State, addr: net.Address, socket: posix.socket_t) !Pong {
    log.info("Initializing Pong game with server address: {any}", .{addr});

    const paddle_1 = Paddle.init(state.internal.player1.paddle.hitbox);
    log.debug("Initialized paddle for player 1: {any}", .{state.internal.player1.paddle.hitbox});

    const player_1 = Player.init("foo", paddle_1, rl.Color.red);
    log.debug("Initialized player 1 with paddle and color: {any}", .{rl.Color.red});

    const paddle_2 = Paddle.init(state.internal.player2.paddle.hitbox);
    log.debug("Initialized paddle for player 2: {any}", .{state.internal.player2.paddle.hitbox});

    const player_2 = Player.init("foo", paddle_2, rl.Color.red);
    log.debug("Initialized player 2 with paddle and color: {any}", .{rl.Color.red});

    const board = Board.init(state.internal.board.dimension, rl.Color.black, rl.Color.white);
    log.info("Initialized game board with dimensions: {any}", .{state.internal.board.dimension});

    const ball = Ball.init(@floatFromInt(state.internal.ball.radius), board.getCenter(), rl.Color.orange, rl.Color.pink);
    log.info("Initialized ball with radius: {d} and colors: {any}, {any}", .{ state.internal.ball.radius, rl.Color.orange, rl.Color.pink });

    const server = try PongServer.init(gpa, addr, socket);
    log.info("Initialized Pong server successfully at {any}", .{addr});

    return .{
        .state = state,
        .gpa = gpa,
        .player1 = player_1,
        .player2 = player_2,
        .board = board,
        .ball = ball,
        .server = server,
    };
}

pub fn drawBoard(self: Pong) void {
    log.debug("Drawing game board...", .{});
    self.board.drawBoardBackground();
    self.board.drawBoardMiddleLine();
    self.board.drawBoardLines();
    log.debug("Finished drawing game board.", .{});
}

pub fn drawBall(self: Pong) void {
    log.debug("Drawing ball...", .{});
    self.ball.drawBackground();
    self.ball.drawLines();
    if (builtin.mode == .Debug) {
        log.debug("Drawing ball hitbox (debug mode).", .{});
        self.ball.drawHitBox();
    }
    log.debug("Finished drawing ball.", .{});
}

pub fn drawPaddles(self: Pong) void {
    log.debug("Drawing paddles...", .{});
    self.player1.paddle.drawBackground(self.player1.color);
    log.debug("Drew player 1's paddle with color: {any}", .{self.player1.color});

    self.player1.paddle.drawLines(self.board.fg);
    self.player2.paddle.drawBackground(self.player2.color);
    log.debug("Drew player 2's paddle with color: {any}", .{self.player2.color});

    self.player2.paddle.drawLines(self.board.fg);
    log.debug("Finished drawing paddles.", .{});
}

pub fn sendUpdate(self: *Pong, out_state: *lib.State) !void {
    log.debug("Sending game state update to server...", .{});
    var state: []u8 = out_state.ptr;
    _ = self.server.putResponse(&state);
    try self.server.write();
    log.info("Game state update sent to server successfully.", .{});
}

pub fn getUpdate(self: *Pong, out_state: *lib.State) !void {
    log.debug("Receiving game state update from server...", .{});
    var state: []u8 = out_state.ptr;
    try self.server.read();
    _ = self.server.getRequest(&state);
    log.info("Game state update received from server successfully.", .{});
}

pub fn updateInternalState(self: *Pong, out_state: *lib.State) void {
    log.debug("Updating internal game state...", .{});
    self.*.state = out_state.*;
    log.info("Internal game state updated successfully.", .{});
}

pub fn getInternalStateCopy(self: *Pong) lib.State {
    log.debug("Creating a copy of the internal game state...", .{});
    return self.state;
}
