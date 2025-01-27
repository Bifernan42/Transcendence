// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   main.zig                                           :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/27 10:46:19 by pollivie          #+#    #+#             //
//   Updated: 2025/01/27 10:46:19 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const lib = @import("libpong");
const process = std.process;
const heap = std.heap;
const mem = std.mem;
const net = std.net;
const cli = lib.cli;
const log = std.log;

pub fn main() !void {
    var gpa: heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();

    var argv = try process.argsWithAllocator(gpa.allocator());
    defer argv.deinit();

    const params: cli.CliFlags = cli.parseCliFlags(&argv);
    log.debug("{any}", .{params});

    const address: net.Address = try .parseIp(params.ip, params.port);
    var server = try address.listen(.{
        .reuse_address = true,
        .reuse_port = true,
    });
    defer server.deinit();

    var state: lib.Message = .zero;
    state.curr_state.board = params.board;
    state.curr_state.kind = params.kind;
    state.curr_state.player1.paddle.hitbox = params.paddle.hitbox;

    const connection = try server.accept();
    while (true) {
        const msg = std.mem.asBytes(&state);
        var buff: [lib.MessageTotalBytes]u8 = undefined;

        const wlne = try connection.stream.write(msg);
        log.debug("{} sent : {d} bytes [{}]", .{ server.listen_address, wlne, state });

        std.posix.nanosleep(1, 0);

        const rlen = try connection.stream.read(&buff);
        state = mem.bytesAsValue(lib.Message, buff[0..]).*;

        log.debug("{} received : {d} bytes [{s}]", .{ server.listen_address, rlen, state });
    }
}
