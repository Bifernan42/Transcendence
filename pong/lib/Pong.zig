// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Pong.zig                                           :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/30 14:39:00 by pollivie          #+#    #+#             //
//   Updated: 2025/02/02 09:13:36 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const lib = @import("root.zig");
const Config = @import("Config.zig");
const Pong = @This();

options: Config.PongOptions = Config.PongOptions.default,
player1: Player = Player.default,
player2: Player = Player.default,
board: Board = Board.default,
ball: Ball = Ball.default,

pub fn init(options: Config.PongOptions) Pong {
    const paddle1: Paddle = .init(options.getPlayer1Paddle());
    const paddle2: Paddle = .init(options.getPlayer2Paddle());
    const board: Board = .init(options.getBoard());
    const ball: Ball = .init(options.getBallPosition(), @floatFromInt(options.ball_radius));
    switch (options.game_kind) {
        .local_ai => {
            return .{
                .options = options,
                .board = board,
                .ball = ball,
                .player1 = Player.init(.player1, paddle1),
                .player2 = Player.init(.bot, paddle2),
            };
        },
        .local_mp => {
            return .{
                .options = options,
                .board = board,
                .ball = ball,
                .player1 = Player.init(.player1, paddle1),
                .player2 = Player.init(.player2, paddle2),
            };
        },
        .remote_mp => {
            return .{
                .options = options,
                .board = board,
                .ball = ball,
                .player1 = Player.init(.player1, paddle1),
                .player2 = Player.init(.player2, paddle2),
            };
        },
    }
}

pub fn initFromResponse(response: lib.Response) Pong {
    return .{
        .player1 = Player.init(.player1, .{
            .dimension = .{
                .x = @floatFromInt(response.player1_x),
                .y = @floatFromInt(response.player1_y),
                .width = @floatFromInt(response.paddle_width),
                .height = @floatFromInt(response.paddle_height),
            },
            .speed = 0,
        }),
        .player2 = Player.init(.player2, .{
            .dimension = .{
                .x = @floatFromInt(response.player2_x),
                .y = @floatFromInt(response.player2_y),
                .width = @floatFromInt(response.paddle_width),
                .height = @floatFromInt(response.paddle_height),
            },
            .speed = 0,
        }),
        .board = Board.init(.{
            .x = 0.0,
            .y = 0.0,
            .width = @floatFromInt(response.board_width),
            .height = @floatFromInt(response.board_height),
        }),
        .ball = Ball.init(
            .{
                .x = @floatFromInt(response.ball_x),
                .y = @floatFromInt(response.ball_y),
            },
            @floatFromInt(response.ball_radius),
        ),
    };
}

pub fn serialize(self: *const Pong) lib.Response {
    return .{
        .board_width = self.options.board_width,
        .board_height = self.options.board_height,
        .paddle_width = self.options.paddle_width,
        .paddle_height = self.options.paddle_height,
        .player1_x = self.player1.getX(),
        .player1_y = self.player1.getY(),
        .player2_x = self.player2.getX(),
        .player2_y = self.player2.getY(),
        .ball_radius = self.options.ball_radius,
        .ball_x = self.ball.getX(),
        .ball_y = self.ball.getY(),
        .player1_score = self.player1.getScore(),
        .player2_score = self.player2.getScore(),
        .player1_status = self.player1.getStatus(),
        .player2_status = self.player2.getStatus(),
        .timestamp = std.time.milliTimestamp(),
        ._padding = 0,
    };
}

pub fn processRequest(self: *Pong, request: *lib.Request) void {
    self.player1.setAction(request.player1_action);
    self.player1.move(@floatFromInt(self.options.paddle_speed), &self.board);
    self.player2.setAction(request.player2_action);
    self.player2.move(@floatFromInt(self.options.paddle_speed), &self.board);
}

pub fn drawBoard(self: Pong, number_of_strip: u8, thickness: f32, fg: rl.Color, bg: rl.Color) void {
    self.board.drawBoardLines(thickness, fg);
    self.board.drawBoardBackground(bg);
    self.board.drawBoardCenterStripLine(number_of_strip, fg, bg);
}

pub fn drawPaddles(self: Pong, thickness: f32, fg: rl.Color, bg: rl.Color) void {
    self.player1.paddle.drawPaddleLines(thickness, fg);
    self.player1.paddle.drawPaddleBackground(bg);
    self.player2.paddle.drawPaddleLines(thickness, fg);
    self.player2.paddle.drawPaddleBackground(bg);
}

pub fn drawBall(self: Pong, thickness: ?f32, fg: rl.Color, bg: rl.Color) void {
    if (thickness) |v| {
        self.ball.drawHitBox(v, fg);
    }
    self.ball.drawBallLines(fg);
    self.ball.drawBallBackground(bg);
}

pub const Player = struct {
    client_id: u32 = 0,
    score: u8 = 0,
    role: lib.PlayerKind = .player1,
    action: lib.PlayerAction = lib.PlayerAction.pressed_none,
    paddle: Paddle = Paddle.default,
    status: lib.PlayerStatus = .absent,

    pub fn init(role: lib.PlayerKind, paddle: Paddle) Player {
        return .{
            .client_id = @intFromEnum(role),
            .score = 0,
            .action = lib.PlayerAction.pressed_none,
            .role = role,
            .paddle = paddle,
            .status = .absent,
        };
    }

    pub fn setAction(self: *Player, action: lib.PlayerAction) void {
        self.action = action;
    }

    pub fn setStatus(self: *Player, status: lib.PlayerStatus) void {
        self.status = status;
    }

    pub fn setScore(self: *Player, score: u8) void {
        self.score = score;
    }

    pub fn setId(self: *Player, id: u32) void {
        self.client_id = id;
    }

    pub fn setRole(self: *Player, role: lib.PlayerKind) void {
        self.role = role;
    }

    pub fn move(self: *Player, amount: f32, board: *const Board) void {
        switch (self.action) {
            .pressed_up => self.paddle.moveUp(amount, board.dimension),
            .pressed_down => self.paddle.moveDown(amount, board.dimension),
            else => {},
        }
        self.action = .pressed_none;
    }

    pub inline fn getScore(self: *const Player) u8 {
        return self.score;
    }

    pub inline fn getStatus(self: *const Player) lib.PlayerStatus {
        return self.status;
    }

    pub inline fn getX(self: *const Player) u32 {
        return @intFromFloat(self.paddle.dimension.x);
    }

    pub inline fn getY(self: *const Player) u32 {
        return @intFromFloat(self.paddle.dimension.y);
    }

    pub const default: Player = .{
        .client_id = 0,
        .score = 0,
        .role = lib.PlayerKind.player1,
        .action = lib.PlayerAction.pressed_none,
        .paddle = Paddle.default,
    };
};

pub const Paddle = struct {
    dimension: rl.Rectangle = lib.default_rectangle,
    speed: f32 = 0.0,

    pub fn init(dimension: rl.Rectangle) Paddle {
        return .{
            .dimension = dimension,
        };
    }

    pub fn drawPaddleLines(self: Paddle, thickness: f32, color: rl.Color) void {
        rl.drawRectangleLinesEx(self.dimension, thickness, color);
    }

    pub fn drawPaddleBackground(self: Paddle, color: rl.Color) void {
        rl.drawRectangleRec(self.dimension, color);
    }

    fn moveOrClip(self: *Paddle, new_position: rl.Vector2, bounds: rl.Rectangle) void {
        const new_paddle_pos: rl.Rectangle = .{
            .x = new_position.x,
            .y = new_position.y,
            .width = self.dimension.width,
            .height = self.dimension.height,
        };

        if (new_paddle_pos.y >= 0 and new_position.y <= (bounds.height - self.dimension.height)) {
            self.dimension = new_paddle_pos;
        }
    }

    pub fn moveUp(self: *Paddle, amount: f32, bounds: rl.Rectangle) void {
        self.moveOrClip(
            .{
                .x = self.dimension.x,
                .y = self.dimension.y - amount,
            },
            bounds,
        );
    }

    pub fn moveDown(self: *Paddle, amount: f32, bounds: rl.Rectangle) void {
        self.moveOrClip(
            .{
                .x = self.dimension.x,
                .y = self.dimension.y + amount,
            },
            bounds,
        );
    }

    pub const default: Paddle = .{
        .dimension = lib.default_rectangle,
        .speed = 0.0,
    };
};

pub const Ball = struct {
    position: rl.Vector2 = lib.default_vector2,
    velocity: rl.Vector2 = lib.default_vector2,
    radius: f32 = 0.0,
    speed: f32 = 0.0,

    pub fn init(position: rl.Vector2, radius: f32) Ball {
        return .{
            .position = position,
            .radius = radius,
        };
    }

    pub fn getHitbox(self: Ball) rl.Rectangle {
        return .{
            .x = self.position.x - self.radius,
            .y = self.position.y - self.radius,
            .width = self.radius * 2.5,
            .height = self.radius * 2.5,
        };
    }

    pub inline fn getX(self: *const Ball) u32 {
        return @intFromFloat(self.position.x);
    }

    pub inline fn getY(self: *const Ball) u32 {
        return @intFromFloat(self.position.y);
    }

    pub fn drawBallLines(self: Ball, color: rl.Color) void {
        rl.drawCircleLinesV(self.position, self.radius, color);
    }

    pub fn drawBallBackground(self: Ball, color: rl.Color) void {
        rl.drawCircleV(self.position, self.radius, color);
    }

    pub fn drawHitBox(self: Ball, thickness: f32, color: rl.Color) void {
        rl.drawRectangleLinesEx(self.getHitbox(), thickness, color);
    }

    pub const default: Ball = .{
        .position = lib.default_vector2,
        .velocity = lib.default_vector2,
        .radius = 0.0,
        .speed = 0.0,
    };
};

pub const Board = struct {
    dimension: rl.Rectangle = lib.default_rectangle,

    pub fn init(dimension: rl.Rectangle) Board {
        return .{
            .dimension = dimension,
        };
    }

    pub fn getCenter(self: Board) rl.Vector2 {
        return .{
            .x = self.dimension.width / 2.0,
            .y = self.dimension.height / 2.0,
        };
    }

    pub fn drawBoardLines(self: Board, thickness: f32, color: rl.Color) void {
        rl.drawRectangleLinesEx(self.dimension, thickness, color);
    }

    pub fn drawBoardBackground(self: Board, color: rl.Color) void {
        rl.drawRectangleRec(self.dimension, color);
    }

    pub fn drawBoardCenterStripLine(self: Board, number_of_strip: u8, fg: rl.Color, bg: rl.Color) void {
        const total_length = self.dimension.height;
        const strip_length = @divExact(total_length, @as(f32, @floatFromInt(number_of_strip)));

        const start: rl.Vector2 = .{
            .x = @divExact(self.dimension.width, 2),
            .y = 0,
        };

        for (0..number_of_strip) |n| {
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

    pub const default: Board = .{
        .dimension = lib.default_rectangle,
    };
};
