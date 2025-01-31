// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   main.zig                                           :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/30 10:09:02 by pollivie          #+#    #+#             //
//   Updated: 2025/01/30 10:09:02 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const lib = @import("libpong");
const heap = std.heap;
const mem = std.mem;
const net = std.net;
const log = std.log;

pub fn main() !void {
    var gpa: heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();

    var request: lib.Request = .default;
    var response: lib.Response = .default;

    const stream = try net.tcpConnectToHost(gpa.allocator(), "127.0.0.1", 8080);
    defer stream.close();

    _ = try stream.write(request.toBytes());
    _ = try stream.read(response.toBytes());

    rl.initWindow(@intCast(response.screen_width), @intCast(response.screen_height), "Pong Client");
    defer rl.closeWindow();

    const padd1: lib.Paddle = .init(.{
        .x = response.player1_paddle_x,
        .y = response.player1_paddle_y,
        .width = @floatFromInt(response.paddle_width),
        .height = @floatFromInt(response.paddle_height),
    });

    const padd2: lib.Paddle = .init(.{
        .x = response.player2_paddle_x,
        .y = response.player2_paddle_y,
        .width = @floatFromInt(response.paddle_width),
        .height = @floatFromInt(response.paddle_height),
    });

    const p1: lib.Player = .init(.player1, padd1);
    const p2: lib.Player = .init(.player2, padd2);

    const board: lib.Board = .init(.{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(response.screen_width),
        .height = @floatFromInt(response.screen_height),
    });

    const ball: lib.Ball = .init(
        .{
            .x = response.ball_position_x,
            .y = response.ball_position_y,
        },
        response.ball_radius,
    );

    var pong: lib.Pong = .init(p1, p2, board, ball);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        pong.drawBoard(128, 5, rl.Color.yellow, rl.Color.dark_gray);
        pong.drawPaddles(4, rl.Color.red, rl.Color.blue);
        pong.drawBall(null, rl.Color.light_gray, rl.Color.white);
        rl.drawFPS(20, 20);
        rl.endDrawing();

        if (rl.isKeyPressed(.w)) {
            request.p1_action = .on_key_press_p1_up;
            request.timestamp = std.time.timestamp();
        } else if (rl.isKeyPressed(.s)) {
            request.p1_action = .on_key_press_p1_down;
            request.timestamp = std.time.timestamp();
        }

        if (rl.isKeyPressed(.up)) {
            request.p1_action = .on_key_press_p2_up;
            request.timestamp = std.time.timestamp();
        } else if (rl.isKeyPressed(.down)) {
            request.p1_action = .on_key_press_p2_down;
            request.timestamp = std.time.timestamp();
        }

        try network(stream, &request, &response);
        pong.update(&response);
    }
}

pub fn network(stream: net.Stream, request: *lib.Request, response: *lib.Response) !void {
    _ = try stream.write(request.toBytes());
    _ = try stream.read(response.toBytes());
}
