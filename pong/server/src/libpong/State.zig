// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   State.zig                                          :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/28 10:15:37 by pollivie          #+#    #+#             //
//   Updated: 2025/01/28 10:15:37 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const cli = @import("Cli.zig");
const protocol = @import("protocol.zig");
const aligment = @alignOf(protocol.Pong);

pub const State = struct {
    internal: protocol.Pong = .zero,
    ptr: *align(aligment) [@sizeOf(protocol.Pong)]u8 = undefined,

    pub fn init(config: cli.CliFlags) State {
        var self: State = .{};
        var pong = protocol.Pong.default;
        pong.kind = config.kind;
        pong.player1.paddle.hitbox.width = config.paddle.hitbox.width;
        pong.player1.paddle.hitbox.height = config.paddle.hitbox.height;
        pong.player2.paddle.hitbox.width = config.paddle.hitbox.width;
        pong.player2.paddle.hitbox.height = config.paddle.hitbox.height;
        pong.board.dimension.width = config.board.dimension.width;
        pong.board.dimension.height = config.board.dimension.height;
        pong.player1.padding = config.padd_speed;
        pong.player2.padding = config.padd_speed;
        pong.ball.padding = config.ball_speed;
        self.internal = pong;
        self.ptr = std.mem.asBytes(&self.internal);
        return self;
    }

    // Accessors
    pub fn getPlayer(self: *const State, playerId: u1) protocol.Player {
        return if (playerId == 1) self.internal.player1 else self.internal.player2;
    }

    pub fn getPaddle(self: *const State, playerId: u1) protocol.Paddle {
        return if (playerId == 1) self.internal.player1.paddle else self.internal.player2.paddle;
    }

    pub fn getBoard(self: *const State) protocol.Board {
        return self.internal.board;
    }

    pub fn getBall(self: *const State) protocol.Ball {
        return self.internal.ball;
    }

    pub fn getGameState(self: *const State, isCurrent: bool) protocol.PongState {
        return if (isCurrent) self.internal.curr_state else self.internal.prev_state;
    }

    pub fn getKind(self: *const State) protocol.PongKind {
        return self.internal.kind;
    }

    pub fn getScore(self: *const State, playerId: u1) protocol.PlayerScore {
        return if (playerId == 1) self.internal.player1.score else self.internal.player2.score;
    }

    pub fn getLastHitSurface(self: *const State) protocol.Surface {
        return self.internal.ball.last_hit;
    }

    // Setters
    pub fn setPaddlePosition(self: *State, playerId: u1, position: protocol.Vector2) void {
        if (playerId == 1) {
            self.internal.player1.paddle.hitbox.position = position;
        } else {
            self.internal.player2.paddle.hitbox.position = position;
        }
    }

    pub fn setBallPosition(self: *State, position: protocol.Vector2) void {
        self.internal.ball.hitbox.position = position;
    }

    pub fn setBallVelocity(self: *State, velocity: protocol.Vector2) void {
        self.internal.ball.velocity = velocity;
    }

    pub fn setGameState(self: *State, newState: protocol.PongState) void {
        self.internal.prev_state = self.internal.curr_state;
        self.internal.curr_state = newState;
    }

    pub fn setScore(self: *State, playerId: u1, score: protocol.PlayerScore) void {
        if (playerId == 1) {
            self.internal.player1.score = score;
        } else {
            self.internal.player2.score = score;
        }
    }

    pub fn setKind(self: *State, kind: protocol.PongKind) void {
        self.internal.kind = kind;
    }

    pub fn setLastHitSurface(self: *State, surface: protocol.Surface) void {
        self.internal.ball.last_hit = surface;
    }

    // Utility
    pub fn resetBall(self: *State, defaultPosition: protocol.Vector2) void {
        self.setBallPosition(defaultPosition);
        self.setBallVelocity(protocol.Vector2.zero);
    }

    pub fn updatePaddleHitbox(
        self: *State,
        playerId: u1,
        width: u16,
        height: u16,
    ) void {
        var paddle = self.getPaddle(playerId);
        paddle.hitbox.width = width;
        paddle.hitbox.height = height;

        if (playerId == 1) {
            self.internal.player1.paddle = paddle;
        } else {
            self.internal.player2.paddle = paddle;
        }
    }

    pub fn incrementScore(self: *State, playerId: u1) void {
        if (playerId == 1) {
            self.internal.player1.score = @as(protocol.PlayerScore, @enumFromInt(self.internal.player1.score + 1));
        } else {
            self.internal.player2.score = @as(protocol.PlayerScore, @enumFromInt(self.internal.player2.score + 1));
        }
    }

    pub fn togglePause(self: *State) void {
        self.internal.curr_state.is_game_paused = !self.internal.curr_state.is_game_paused;
    }

    // GETTERS

    pub fn isBallHit(self: *const State) bool {
        return self.is_ball_hit == 1;
    }

    pub fn isBallReset(self: *const State) bool {
        return self.internal.curr_state.is_ball_reset == 1;
    }

    pub fn isGameBegin(self: *const State) bool {
        return self.internal.curr_state.is_game_begin == 1;
    }
    pub fn isGameDone(self: *const State) bool {
        return self.internal.curr_state.is_game_done == 1;
    }

    pub fn isGamePaused(self: *const State) bool {
        return self.internal.curr_state.is_game_paused == 1;
    }

    pub fn isGamePlaying(self: *const State) bool {
        return self.internal.curr_state.is_game_playing == 1;
    }

    pub fn isPlayer1KO(self: *const State) bool {
        return self.internal.curr_state.is_player_1_ko == 1;
    }

    pub fn isPlayer1Mov(self: *const State) bool {
        return self.internal.curr_state.is_player_1_mov == 1;
    }

    pub fn isPlayer1OK(self: *const State) bool {
        return self.internal.curr_state.is_player_1_ok == 1;
    }

    pub fn isPlayer1Seen(self: *const State) bool {
        return self.internal.curr_state.is_player_1_seen == 1;
    }

    pub fn isPlayer2KO(self: *const State) bool {
        return self.internal.curr_state.is_player_2_ko == 1;
    }

    pub fn isPlayer2Mov(self: *const State) bool {
        return self.internal.curr_state.is_player_2_mov == 1;
    }

    pub fn isPlayer2OK(self: *const State) bool {
        return self.internal.curr_state.is_player_2_ok == 1;
    }

    pub fn isPlayer2Seen(self: *const State) bool {
        return self.internal.curr_state.is_player_2_seen == 1;
    }

    pub fn wasBallHit(self: *const State) bool {
        return self.internal.prev_state.is_ball_hit == 1;
    }

    pub fn wasBallReset(self: *const State) bool {
        return self.internal.prev_state.is_ball_reset == 1;
    }

    pub fn wasGameBegin(self: *const State) bool {
        return self.internal.prev_state.is_game_begin == 1;
    }

    pub fn wasGameDone(self: *const State) bool {
        return self.internal.prev_state.is_game_done == 1;
    }

    pub fn wasGamePaused(self: *const State) bool {
        return self.internal.prev_state.is_game_paused == 1;
    }

    pub fn wasGamePlaying(self: *const State) bool {
        return self.internal.prev_state.is_game_playing == 1;
    }

    pub fn wasPlayer1KO(self: *const State) bool {
        return self.internal.prev_state.is_player_1_ko == 1;
    }

    pub fn wasPlayer1Mov(self: *const State) bool {
        return self.internal.prev_state.is_player_1_mov == 1;
    }

    pub fn wasPlayer1OK(self: *const State) bool {
        return self.internal.prev_state.is_player_1_ok == 1;
    }

    pub fn wasPlayer1Seen(self: *const State) bool {
        return self.internal.prev_state.is_player_1_seen == 1;
    }

    pub fn wasPlayer2KO(self: *const State) bool {
        return self.internal.prev_state.is_player_2_ko == 1;
    }

    pub fn wasPlayer2Mov(self: *const State) bool {
        return self.internal.prev_state.is_player_2_mov == 1;
    }

    pub fn wasPlayer2OK(self: *const State) bool {
        return self.internal.prev_state.is_player_2_ok == 1;
    }

    pub fn wasPlayer2Seen(self: *const State) bool {
        return self.internal.prev_state.is_player_2_seen == 1;
    }

    // SETTERS

    pub fn setBallHit(self: *State, value: bool) void {
        self.internal.curr_state.is_ball_hit = if (value) 1 else 0;
    }

    pub fn setBallReset(self: *State, value: bool) void {
        self.internal.curr_state.is_ball_reset = if (value) 1 else 0;
    }

    pub fn setGameBegin(self: *State, value: bool) void {
        self.internal.curr_state.is_game_begin = if (value) 1 else 0;
    }

    pub fn setGameDone(self: *State, value: bool) void {
        self.internal.curr_state.is_game_done = if (value) 1 else 0;
    }

    pub fn setGamePaused(self: *State, value: bool) void {
        self.internal.curr_state.is_game_paused = if (value) 1 else 0;
    }

    pub fn setGamePlaying(self: *State, value: bool) void {
        self.internal.curr_state.is_game_playing = if (value) 1 else 0;
    }

    pub fn setPlayer1KO(self: *State, value: bool) void {
        self.internal.curr_state.is_player_1_ko = if (value) 1 else 0;
    }

    pub fn setPlayer1Mov(self: *State, value: bool) void {
        self.internal.curr_state.is_player_1_mov = if (value) 1 else 0;
    }

    pub fn setPlayer1OK(self: *State, value: bool) void {
        self.internal.curr_state.is_player_1_ok = if (value) 1 else 0;
    }

    pub fn setPlayer1Seen(self: *State, value: bool) void {
        self.internal.curr_state.is_player_1_seen = if (value) 1 else 0;
    }

    pub fn setPlayer2KO(self: *State, value: bool) void {
        self.internal.curr_state.is_player_2_ko = if (value) 1 else 0;
    }

    pub fn setPlayer2Mov(self: *State, value: bool) void {
        self.internal.curr_state.is_player_2_mov = if (value) 1 else 0;
    }

    pub fn setPlayer2OK(self: *State, value: bool) void {
        self.internal.curr_state.is_player_2_ok = if (value) 1 else 0;
    }

    pub fn setPlayer2Seen(self: *State, value: bool) void {
        self.internal.curr_state.is_player_2_seen = if (value) 1 else 0;
    }
};
