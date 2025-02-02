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

const full_write_size = @sizeOf(lib.Request);
const full_read_size = @sizeOf(lib.Response);

pub fn main() !void {
    var gpa: heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();

    var request: lib.Request = lib.Request.init();
    var response: lib.Response = lib.Response.init();

    const stream = try net.tcpConnectToHost(gpa.allocator(), "127.0.0.1", 8080);
    defer stream.close();

    sendAndFetchPongStates(stream, &request, &response) catch |err| {
        log.err("fatal error encountered : {!}. closing now.", .{err});
        return;
    };

    rl.initWindow(@intCast(response.board_width), @intCast(response.board_height), "Pong Client");
    defer rl.closeWindow();

    var req: lib.Request = request;
    var res: lib.Response = response;
    rl.setTargetFPS(120);
    while (!rl.windowShouldClose()) {
        var pong: lib.Pong = .initFromResponse(res);

        log.debug("sending {}, received {}", .{ req, res });
        renderPongState(&pong);
        updatePongState(&req);
        sendAndFetchPongStates(stream, &req, &res) catch |err| {
            log.err("fatal error encountered : {!}. closing now.", .{err});
            break;
        };
    }
}

pub fn updatePongState(request: *lib.Request) void {
    request.player1_action = .pressed_none;
    request.player2_action = .pressed_none;
    if (rl.isKeyDown(.w)) {
        request.player1_action = .pressed_up;
    } else if (rl.isKeyDown(.s)) {
        request.player1_action = .pressed_down;
    } else if (rl.isKeyDown(.up)) {
        request.player2_action = .pressed_up;
    } else if (rl.isKeyDown(.down)) {
        request.player2_action = .pressed_down;
    }
    request.timestamp = std.time.milliTimestamp();
}

pub fn renderPongState(pong: *const lib.Pong) void {
    rl.beginDrawing();
    rl.clearBackground(rl.Color.black);
    rl.clearBackground(rl.Color.black);
    pong.drawBoard(128, 4.0, rl.Color.gold, rl.Color.dark_gray);
    pong.drawPaddles(4.0, rl.Color.red, rl.Color.orange);
    pong.drawBall(2.0, rl.Color.green, rl.Color.dark_green);
    rl.drawFPS(20, 20);
    rl.endDrawing();
}

pub fn sendAndFetchPongStates(stream: net.Stream, request: *lib.Request, response: *lib.Response) !void {
    const bytes_written = try stream.write(request.asBytes());
    const bytes_read = try stream.read(response.asBytes());
    if (bytes_written != full_write_size or bytes_read != full_read_size) {
        return error.Closed;
    } else {
        log.info("{} : sent {d} bytes, and received {d} bytes", .{ stream, bytes_written, bytes_read });
    }
}
