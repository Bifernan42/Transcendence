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

    const bytes_written = stream.write(request.asBytes()) catch |err| {
        log.err("fatal error encountered : {!}. closing now.", .{err});
        return;
    };
    const bytes_read = stream.read(response.asBytes()) catch |err| {
        log.err("fatal error encountered : {!}. closing now.", .{err});
        return;
    };

    log.info("{} : sent {d} bytes, and received {d} bytes", .{ stream, bytes_written, bytes_read });

    rl.initWindow(response.board_width, response.board_height, "Pong Client");
    defer rl.closeWindow();

    var req: lib.Request = request;
    var res: lib.Response = response;
    while (!rl.windowShouldClose()) {
        network(stream, &req, &res) catch |err| {
            log.err("fatal error encountered : {!}. closing now.", .{err});
            break;
        };
        rl.beginDrawing();
        rl.clearBackground(rl.Color.black);
        rl.drawRectangleLines(0, 0, res.board_width, res.board_height, rl.Color.light_gray);
        rl.drawRectangle(0, 0, res.board_width, res.board_height, rl.Color.black);
        rl.drawFPS(20, 20);

        rl.endDrawing();
    }
}

pub fn network(stream: net.Stream, request: *lib.Request, response: *lib.Response) !void {
    const bytes_written = try stream.write(request.asBytes());
    const bytes_read = try stream.read(response.asBytes());
    if (bytes_written != full_write_size or bytes_read != full_read_size) {
        return error.Closed;
    } else {
        log.info("{} : sent {d} bytes, and received {d} bytes", .{ stream, bytes_written, bytes_read });
    }
}
