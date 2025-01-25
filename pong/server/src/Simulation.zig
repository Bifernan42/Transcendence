// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Simulation.zig                                     :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/25 17:48:34 by pollivie          #+#    #+#             //
//   Updated: 2025/01/25 17:48:35 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const math = std.math;
const time = std.time;
const heap = std.heap;
const json = std.json;
const Allocator = mem.Allocator;
const assert = std.debug.assert;
const net = std.net;
const log = std.log;
const posix = std.posix;
const builtin = @import("builtin");
const Protocol = @import("Protocol.zig");
const Pong = @import("Pong.zig");
const Client = @import("Client.zig");
const Config = @import("Config.zig");
const History = std.AutoArrayHashMapUnmanaged(i64, Pong.GameState);
const Buffer = Protocol.Buffer;
const Simulation = @This();

pub const Identity = enum { player1, player2, ai, spectator };

gpa: mem.Allocator,
kind: Pong.GameKind,
state: Pong.GameState,
config: Config,
clock: time.Timer,
history: History,
internal: InternalState,

pub fn init(gpa: mem.Allocator, config: Config) Simulation {
    return .{
        .config = config,
        .gpa = gpa,
        .kind = config.game_kind,
        .state = Pong.GameState.initFromConfig(config),
        .clock = time.Timer.start() catch unreachable,
        .history = History.empty,
        .internal = InternalState.init(config, gpa),
    };
}

pub fn tick(simulation: *Simulation) Pong.GameState {
    return simulation.state;
}

pub fn whoIs(simulation: *const Simulation, name: []const u8) Identity {
    if (mem.eql(u8, name, simulation.state.player1.name)) {
        return Identity.player1;
    } else if (mem.eql(u8, name, simulation.state.player2.name)) {
        return Identity.player2;
    } else if (simulation.kind == .local_ai) {
        return Identity.ai;
    }
    return Identity.spectator;
}

pub fn hasPlayer1(simulation: *const Simulation) bool {
    return simulation.internal.isRegistered(.player1);
}

pub fn deinit(self: *Simulation) void {
    self.history.deinit(self.gpa);
    self.internal.deinit();
}

const InternalState = struct {
    player1: ?Pong.Player,
    player2: ?Pong.Player,
    token_id1: usize,
    token_id2: usize,
    ai: Pong.Player,
    board: Pong.Board,
    ball: Pong.Ball,
    config: Config,
    input_queue: Buffer(Pong.Player.Event),

    pub fn init(config: Config, allocator: mem.Allocator) InternalState {
        return .{
            .player1 = null,
            .player2 = null,
            .ai = Pong.Player.ai,
            .token_id1 = 0,
            .token_id2 = 0,
            .board = Pong.Board.initFromConfig(config),
            .ball = Pong.Ball.initFromConfig(config),
            .config = config,
            .input_queue = Buffer(Pong.Player.Event).init(allocator),
        };
    }

    pub fn isRegistered(self: InternalState, entity: Identity) bool {
        return switch (entity) {
            .player1 => if (self.player1) |_| true else false,
            .player2 => if (self.player2) |_| true else false,
            .ai, .spectator => true,
        };
    }

    pub fn register(self: *InternalState, entity: Identity, token_id: u64) void {
        switch (entity) {
            .player1 => {
                self.player1 = Pong.Player.initFromConfig(self.config, .p1);
                self.token_id1 = token_id;
            },
            .player2 => {
                self.player2 = Pong.Player.initFromConfig(self.config, .p2);
                self.token_id2 = token_id;
            },
            else => unreachable,
        }
    }

    pub fn id(self: *InternalState, token_id: u64) ?Identity {
        if (self.token_id1 == token_id) {
            return .player1;
        } else if (self.token_id2 == token_id) {
            return .player2;
        }
        return null;
    }

    pub fn registerInput(self: *InternalState, maybe_from: ?Identity, input: Pong.Player.Event) bool {
        const from = maybe_from orelse return false;
        switch (from) {
            .player1 => self.input_queue.pushBack(input) catch return false,
            .player2 => self.input_queue.pushBack(input) catch return false,
            .ai => self.input_queue.pushBack(input) catch return false,
            else => return false,
        }
        return false;
    }

    pub fn deinit(self: *InternalState) void {
        self.input_queue.deinit();
    }
};
