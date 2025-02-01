// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Pong.zig                                           :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/30 14:39:00 by pollivie          #+#    #+#             //
//   Updated: 2025/01/30 14:39:00 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const lib = @import("libpong");
pub const Pong = @This();

board_width: u16,
board_height: u16,
paddle_width: u16,
paddle_height: u16,
paddle_speed: u16,
player1_x: u16,
player1_y: u16,
player2_x: u16,
player2_y: u16,
ball_radius: u16,
ball_speed: u16,
ball_x: u16,
ball_y: u16,
ball_dx: u16,
ball_dy: u16,
player1_score: u8,
player2_score: u8,
player1_status: lib.PlayerStatus,
player2_status: lib.PlayerStatus,
player1_move: lib.PlayerAction,
player2_move: lib.PlayerAction,
last_update: i64,
now_update: i64,
kind: Kind,

pub const Kind = enum {
    local_ai,
    local_mp,
    remote_mp,
};

pub fn init(option: PongOptions) Pong {
    return .{
        .board_width = option.board_width,
        .board_height = option.board_height,
        .paddle_width = option.paddle_width,
        .paddle_height = option.paddle_height,
        .paddle_speed = option.paddle_speed,
        .ball_speed = option.ball_speed,
        .ball_dx = 0.0,
        .ball_dy = 0.0,
        .player1_x = option.getPlayer1StartX(),
        .player1_y = option.getPlayer1StartY(),
        .player2_x = option.getPlayer2StartX(),
        .player2_y = option.getPlayer2StartY(),
        .ball_radius = option.ball_radius,
        .ball_x = option.getBallStartX(),
        .ball_y = option.getBallStartY(),
        .player1_score = 0,
        .player2_score = 0,
        .player1_status = .unavailable,
        .player2_status = .unavailable,
        .kind = option.game_kind,
        .player1_move = lib.PlayerAction.pressed_none,
        .player2_move = lib.PlayerAction.pressed_none,
        .last_update = 0,
        .now_update = 0,
    };
}

pub fn serialize(self: *const Pong) lib.Response {
    return .{
        .board_width = self.board_width,
        .board_height = self.board_height,
        .paddle_width = self.paddle_width,
        .paddle_height = self.paddle_height,
        .player1_x = self.player1_x,
        .player1_y = self.player1_y,
        .player2_x = self.player2_x,
        .player2_y = self.player2_y,
        .ball_radius = self.ball_radius,
        .ball_x = self.ball_x,
        .ball_y = self.ball_y,
        .player1_score = self.player1_score,
        .player2_score = self.player2_score,
        .player1_status = self.player1_status,
        .player2_status = self.player2_status,
        .timestamp = self.now_update,
        ._padding = 0,
    };
}

pub fn play(self: *Pong) lib.Response {
    self.last_update = self.now_update;
    self.now_update = std.time.milliTimestamp();
    if (self.moveBall()) |hit_something| {
        switch (hit_something) {
            .wall_left => {
                self.player2_score += 1;
                self.resetBall();
            },
            .wall_right => {
                self.player1_score += 1;
                self.resetBall();
            },
            else => {},
        }
    }
    switch (self.kind) {
        .local_ai => {
            self.movePlayer(.player1, self.player1_move);
            self.movePlayer(.bot, self.player2_move);
        },
        .local_mp, .remote_mp => {
            self.movePlayer(.player1, self.player1_move);
            self.movePlayer(.player2, self.player2_move);
        },
    }
    const response = self.serialize();
    self.player1_move = lib.PlayerAction.pressed_none;
    self.player2_move = lib.PlayerAction.pressed_none;
    return response;
}

pub fn movePlayer(self: *Pong, role: lib.Role, action: lib.PlayerAction) void {
    const movement_amount_by_ms: f32 = (@as(f32, @floatFromInt(self.paddle_speed)) / std.time.ms_per_s);
    const amount_of_ms: f32 = @abs(@as(f32, @floatFromInt((self.now_update - self.last_update))));
    const move: f32 = movement_amount_by_ms * amount_of_ms;

    switch (role) {
        .player1 => {
            const translation: rl.Vector2 = switch (action) {
                .pressed_up => .{
                    .x = 0,
                    .y = -move,
                },
                .pressed_down => .{
                    .x = 0,
                    .y = move,
                },
                else => .{
                    .x = 0,
                    .y = 0,
                },
            };
            const movement: rl.Vector2 = .{
                .x = @as(f32, @floatFromInt(self.player1_x)) + translation.x,
                .y = @as(f32, @floatFromInt(self.player1_y)) + translation.y,
            };
            if (movement.y >= 0 and movement.y <= @as(f32, @floatFromInt((self.board_height - self.paddle_height)))) {
                self.player1_x = @intFromFloat(@floor(movement.x));
                self.player1_y = @intFromFloat(@floor(movement.y));
            }
        },
        .player2 => {
            const translation: rl.Vector2 = switch (action) {
                .pressed_up => .{
                    .x = 0,
                    .y = -move,
                },
                .pressed_down => .{
                    .x = 0,
                    .y = move,
                },
                else => .{
                    .x = 0,
                    .y = 0,
                },
            };
            const movement: rl.Vector2 = .{
                .x = @as(f32, @floatFromInt(self.player2_x)) + translation.x,
                .y = @as(f32, @floatFromInt(self.player2_y)) + translation.y,
            };
            if (movement.y >= 0 and movement.y <= @as(f32, @floatFromInt((self.board_height - self.paddle_height)))) {
                self.player2_x = @intFromFloat(@floor(movement.x));
                self.player2_y = @intFromFloat(@floor(movement.y));
            }
        },
        .bot => {
            const ai_action = self.computeBotAction();
            const translation: rl.Vector2 = switch (ai_action) {
                .pressed_up => .{
                    .x = 0,
                    .y = -move,
                },
                .pressed_down => .{
                    .x = 0,
                    .y = move,
                },
                else => .{
                    .x = 0,
                    .y = 0,
                },
            };
            const movement: rl.Vector2 = .{
                .x = @as(f32, @floatFromInt(self.player2_x)) + translation.x,
                .y = @as(f32, @floatFromInt(self.player2_y)) + translation.y,
            };
            if (movement.y >= 0 and movement.y <= @as(f32, @floatFromInt((self.board_height - self.paddle_height)))) {
                self.player2_x = @intFromFloat(@floor(movement.x));
                self.player2_y = @intFromFloat(@floor(movement.y));
            }
        },
        .spectator => return,
    }
}

pub fn resetBall(self: *Pong) void {
    // var randomizer = std.Random.DefaultPrng.init(0);
    // const rand = randomizer.random();
    self.ball_x = @divFloor(self.board_width, 2) - self.ball_radius;
    self.ball_x = @divFloor(self.board_height, 2) - self.ball_radius;
    self.ball_dx = 1;
    self.ball_dy = 1;
}

pub const Hit = enum {
    pad1,
    pad2,
    wall_left,
    wall_right,
    wall_up,
    wall_down,
};

pub fn moveBall(self: *Pong) ?Hit {
    _ = self;
    // var hit: ?Hit = null;
    // self.ball_x = (self.ball_x + self.ball_dx );
    // self.ball_y = (self.ball_y + self.ball_dx );

    // const hitbox: rl.Rectangle = .{
    //     .x = self.ball_x - self.ball_radius,
    //     .y = self.ball_y - self.ball_radius,
    //     .width = self.ball_radius * 2.0,
    //     .height = self.ball_radius * 2.0,
    // };

    // const paddle1: rl.Rectangle = .{
    //     .x = self.player1_x,
    //     .y = self.player1_y,
    //     .width = self.paddle_width,
    //     .height = self.paddle_height,
    // };

    // const paddle2: rl.Rectangle = .{
    //     .x = self.player2_x,
    //     .y = self.player2_y,
    //     .width = self.paddle_width,
    //     .height = self.paddle_height,
    // };

    // if (self.ball_y - self.ball_radius < 0) {
    //     self.ball_dy *= -1; // Reverse Y direction
    //     hit = .wall_up;
    // } else if (self.ball_y + self.ball_radius > self.board_height) {
    //     self.ball_dy *= -1; // Reverse Y direction
    //     hit = .wall_down;
    // }

    // if (rl.checkCollisionRecs(hitbox, paddle1)) {
    //     self.ball_dx *= -1;
    //     hit = .pad1;
    // } else if (rl.checkCollisionRecs(hitbox, paddle2)) {
    //     self.ball_dx *= -1;
    //     hit = .pad2;
    // }

    // if (self.ball_x < paddle1.x) {
    //     hit = .wall_left;
    // } else if (self.ball_x > paddle2.x) {
    //     hit = .wall_right;
    // }

    // return hit;
    return null;
}

pub fn computeBotAction(self: *const Pong) lib.PlayerAction {
    const paddle_center: f32 = @as(f32, @floatFromInt(self.player2_y)) + @as(f32, @floatFromInt(@divFloor(self.paddle_height, 2)));
    const ball_center: f32 = @as(f32, @floatFromInt(self.ball_y));

    if (self.ball_dx > 0) {
        if (paddle_center < ball_center) {
            return lib.PlayerAction.pressed_down;
        } else if (paddle_center > ball_center) {
            return lib.PlayerAction.pressed_up;
        } else {
            return lib.PlayerAction.pressed_none;
        }
    } else {
        if (self.ball_dy > 0) {
            if (ball_center > paddle_center) {
                return lib.PlayerAction.pressed_up;
            } else {
                return lib.PlayerAction.pressed_down;
            }
        } else if (self.ball_dy < 0) {
            if (ball_center < paddle_center) {
                return lib.PlayerAction.pressed_down;
            } else {
                return lib.PlayerAction.pressed_up;
            }
        } else {
            return lib.PlayerAction.pressed_none;
        }
    }
}

pub const DrawOptions = struct {
    board_line_thick: f32 = 8.0,
    board_line_strip_count: u8 = 128,
    board_fg: rl.Color = .white,
    board_bg: rl.Color = .black,
    paddle_fg: rl.Color = .light_gray,
    paddle_bg: rl.Color = .gray,
    ball_fg: rl.Color = .light_gray,
    ball_bg: rl.Color = .red,
    paddle_line_thick: f32 = 4.0,
    ball_line_thick: f32 = 4.0,
};

pub fn draw(self: *const Pong, options: DrawOptions) void {
    self.drawBoard(
        options.board_line_thick,
        options.board_line_strip_count,
        options.board_fg,
        options.board_bg,
    );

    self.drawPaddles(
        options.paddle_line_thick,
        options.paddle_fg,
        options.paddle_bg,
    );

    self.drawBall(
        options.ball_fg,
        options.ball_bg,
    );
}

pub fn drawBoard(self: *const Pong, thickness: f32, strips: u8, fg: rl.Color, bg: rl.Color) void {
    const position: rl.Rectangle = .{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(self.board_width),
        .height = @floatFromInt(self.board_height),
    };

    rl.drawRectangleLinesEx(position, thickness, fg);
    rl.drawRectangleRec(position, bg);

    const strip_length: f32 = @floatFromInt(@divExact(self.board_height, strips));
    const start: rl.Vector2 = .{
        .x = @floatFromInt(@divFloor(self.board_width, 2)),
        .y = 0,
    };

    for (0..strips) |n| {
        const color: rl.Color = if (@mod(n, 2) == 0) bg else fg;

        const from: rl.Vector2 = .{
            .x = start.x,
            .y = strip_length * @as(f32, @floatFromInt(n)),
        };

        const to: rl.Vector2 = .{
            .x = start.x,
            .y = from.y + strip_length,
        };

        rl.drawLineV(from, to, color);
    }
}

pub fn drawPaddles(self: *const Pong, thickness: f32, fg: rl.Color, bg: rl.Color) void {
    const position_p1: rl.Rectangle = .{
        .x = @floatFromInt(self.player1_x),
        .y = @floatFromInt(self.player1_y),
        .width = @floatFromInt(self.paddle_width),
        .height = @floatFromInt(self.paddle_height),
    };

    const position_p2: rl.Rectangle = .{
        .x = @floatFromInt(self.player2_x),
        .y = @floatFromInt(self.player2_y),
        .width = @floatFromInt(self.paddle_width),
        .height = @floatFromInt(self.paddle_height),
    };

    rl.drawRectangleLinesEx(position_p1, thickness, fg);
    rl.drawRectangleLinesEx(position_p2, thickness, fg);
    rl.drawRectangleRec(position_p1, bg);
    rl.drawRectangleRec(position_p2, bg);
}

pub fn drawBall(self: *const Pong, fg: rl.Color, bg: rl.Color) void {
    const position: rl.Vector2 = .{
        .x = @floatFromInt(self.ball_x),
        .y = @floatFromInt(self.ball_y),
    };
    rl.drawCircleLinesV(position, @floatFromInt(self.ball_radius), fg);
    rl.drawCircleV(position, @floatFromInt(self.ball_radius), bg);
}

pub const PongOptions = struct {
    board_width: u16 = 1024.0,
    board_height: u16 = 512.0,
    paddle_width: u16 = 16.0,
    paddle_height: u16 = 8.0,
    paddle_speed: u16 = 8.0,
    ball_radius: u16 = 4.0,
    ball_speed: u16 = 128.0,
    max_score: u8 = 3,
    game_kind: Kind = .local_ai,
    player1_token: u32 = 1,
    player2_token: u32 = 2,
    server_ip: []const u8 = "127.0.0.1",
    server_port: u16 = 8080,
    server_tickrate: u16 = 60,
    server_client_max: u8 = 4,
    server_headless: bool = true,

    pub fn init() PongOptions {
        return PongOptions.default;
    }

    pub fn getPlayer1StartX(self: *const PongOptions) u16 {
        return @divFloor(self.paddle_width, 2);
    }

    pub fn getPlayer1StartY(self: *const PongOptions) u16 {
        return @divFloor(self.board_height, 2) - @divFloor(self.paddle_height, 2);
    }

    pub fn getPlayer2StartX(self: *const PongOptions) u16 {
        return self.board_width - (self.paddle_width + @divFloor(self.paddle_width, 2));
    }

    pub fn getPlayer2StartY(self: *const PongOptions) u16 {
        return @divFloor(self.board_height, 2) - @divFloor(self.paddle_height, 2);
    }

    pub fn getBallStartX(self: *const PongOptions) u16 {
        return @divFloor(self.board_width, 2) - self.ball_radius;
    }

    pub fn getBallStartY(self: *const PongOptions) u16 {
        return @divFloor(self.board_height, 2) - self.ball_radius;
    }

    pub const default: PongOptions = .{
        .board_width = 1024.0,
        .board_height = 512.0,
        .paddle_width = 16.0,
        .paddle_height = 8.0,
        .paddle_speed = 8.0,
        .ball_radius = 4.0,
        .ball_speed = 128.0,
        .max_score = 3,
        .game_kind = .local_ai,
        .player1_token = 1,
        .player2_token = 2,
        .server_ip = "127.0.0.1",
        .server_port = 8080,
        .server_tickrate = 60,
        .server_client_max = 4,
        .server_headless = true,
    };

    pub fn getRole(self: *const PongOptions, id: u32) lib.Role {
        if (self.player1_token == id) {
            return lib.Role.player1;
        } else if (self.player2_token == id) {
            return lib.Role.player2;
        } else {
            return lib.Role.spectator;
        }
    }
};
