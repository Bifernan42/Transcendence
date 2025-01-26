// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   main.zig                                           :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/26 08:11:40 by pollivie          #+#    #+#             //
//   Updated: 2025/01/26 08:11:41 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const lib = @import("libpong");
const prot = lib.protocol;
const heap = std.heap;
const mem = std.mem;
const log = std.log;
const json = std.json;
const net = std.net;
const posix = std.posix;

pub fn main() !void {
    var gpa: heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();

    var server = lib.Server.init(gpa.allocator(), .{});
    defer server.deinit();

    try server.listen(.{
        .ip = "127.0.0.1",
        .port = 8080,
    });

    try run(&server);
}

pub fn run(server: *lib.Server) !void {
    while (true) {
        log.info("{} waiting on events...", .{server.address});
        const polling = server.getPollfds();
        _ = try posix.poll(polling, -1);

        if (polling[0].revents != 0) {
            const connection = server.accept() catch |err| {
                log.err("server failed to accept new client {!}", .{err});
                continue;
            };
            log.info("server accepted new connection : {}", .{connection});
        }

        for (polling[1..]) |client| {
            log.info("client : {any}\n", .{client});
        }
    }
}
