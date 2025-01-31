const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const Pong = @import("pong.zig").Pong;
const PongState = @import("pong.zig").PongState;
const PongError = @import("pong.zig").PongError;
const Player = @import("player.zig").Player;
const Board = @import("board.zig").Board;
const Paddle = @import("paddle.zig").Paddle;
const Ball = @import("ball.zig").Ball;
const SurfaceHit = @import("ball.zig").SurfaceHit;
const Allocator = std.mem.Allocator;
const AllocatorError = Allocator.Error;

pub fn main() !void {
    var buffer: [1024 * 1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(buffer[0..]);
    const allocator = fba.allocator();

    try gameLoop(1280, 768, "Server Side Pong - Client Demo", allocator);
}

fn drawScore(allocator: Allocator, player1_score: u8, player2_score: u8, screen_width: i32) void {
    const font_size = 40;
    const text: [*:0]const u8 = std.fmt.allocPrintZ(allocator, "{d} - {d}", .{ player1_score, player2_score }) catch |err| {
        std.debug.print("Error formatting score: {any}\n", .{err});
        return;
    };

    const text_width = rl.measureText(text, font_size);
    rl.drawText(
        text,
        @divFloor((screen_width - text_width), 2), // Center text horizontally
        10, // Top padding
        font_size,
        rl.Color.light_gray,
    );
}

fn drawRestartButton(screen_width: i32, screen_height: i32) i32 {
    const button_width = 150;
    const button_height = 50;
    const button_x: f32 = @floatFromInt(@divFloor((screen_width - button_width), 2));
    const button_y: f32 = @floatFromInt(@divFloor(screen_height, 2) + 50); // Slightly below the "Winner" text

    return rg.guiButton(.{ .x = button_x, .y = button_y, .width = button_width, .height = button_height }, "Restart");
}

fn gameOverScreen(winner_text: [*:0]const u8, winner_color: rl.Color, screen_width: i32, screen_height: i32) i32 {
    const font_size = 30;
    const text_width = rl.measureText(winner_text, font_size);

    rl.drawText(winner_text, @divFloor((screen_width - text_width), 2), @divFloor(screen_height, 2) - font_size, // Centered vertically
        font_size, winner_color);

    return drawRestartButton(screen_width, screen_height);
}

fn gameLoop(screen_width: i32, screen_height: i32, title: [*:0]const u8, allocator: Allocator) !void {
    rl.initWindow(screen_width, screen_height, title);
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    const paddle_width: f32 = 10.0;
    const paddle_height: f32 = 100.0;
    const paddle_outlines_pixels: f32 = 2.0;
    const pixel_offset = 5.0;

    const paddle_left_player_offset = pixel_offset;
    const paddle_right_player_offset = @as(f32, @floatFromInt(screen_width)) - (paddle_width + paddle_outlines_pixels + pixel_offset);
    const screen_center_x: f32 = @floatFromInt(@divFloor(screen_width, 2));
    const screen_center_y: f32 = @floatFromInt(@divFloor(screen_height, 2));
    const half_paddle_height: f32 = paddle_height / 2;

    const player1 = Player.init("player1", .{
        .dimension = .{
            .x = paddle_left_player_offset,
            .y = screen_center_y - half_paddle_height,
            .width = paddle_width,
            .height = paddle_height,
        },
    }, rl.Color.red);

    const player2 = Player.init("player2", .{
        .dimension = .{
            .x = paddle_right_player_offset,
            .y = screen_center_y - half_paddle_height,
            .width = paddle_width,
            .height = paddle_height,
        },
    }, rl.Color.blue);

    const board = Board.init(.{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(screen_width),
        .height = @floatFromInt(screen_height),
    }, rl.Color.black, rl.Color.white);

    const ball = Ball.init(8, .{
        .x = screen_center_x,
        .y = screen_center_y,
    }, rl.Color.green, rl.Color.white);

    var game = Pong.init(player1, player2, board, ball);

    while (!rl.windowShouldClose()) {
        // Update game state
        if (rl.isKeyPressedRepeat(.w)) game.player1.move(.up, game.board.dimension);
        if (rl.isKeyPressedRepeat(.s)) game.player1.move(.down, game.board.dimension);
        game.player2.moveAi(&game.ball, game.board.dimension);

        const maybe_hit_surface = game.ball.move(rl.getFrameTime(), game.board.dimension, game.player1.paddle.dimension, game.player2.paddle.dimension);

        if (maybe_hit_surface) |surface| {
            switch (surface) {
                .left => game.player2.score += 1,
                .right => game.player1.score += 1,
                else => {},
            }
        }

        rl.beginDrawing();
        rl.clearBackground(rl.Color.white);

        game.drawBoard();
        game.drawBall();
        game.drawPaddles();
        drawScore(allocator, game.player1.score, game.player2.score, screen_width);

        if (game.player1.score >= 3 or game.player2.score >= 3) {
            const winner_text = if (game.player1.score >= 1) "Player 1 Wins!" else "Player 2 Wins!";
            const winner_color = if (game.player1.score >= 3) game.player1.color else game.player2.color;

            const restart = gameOverScreen(winner_text, winner_color, screen_width, screen_height);
            if (restart != 0) {
                game = Pong.init(player1, player2, board, ball);
                continue;
            }
        }

        rl.endDrawing();
    }
}
