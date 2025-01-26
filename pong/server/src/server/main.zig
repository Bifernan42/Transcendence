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
const Server = lib.Server;
const Connection = lib.Connection;
const AuthRequest = prot.Auth.Request;
const AuthResponse = prot.Auth.Response;

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
            if (client.revents == 0) continue;
            const connection = server.getConnection(client.fd) orelse continue;

            switch (connection.states.last_state) {
                .connected => try authentificateClient(server, connection),
                else => {},
            }
        }
    }
}

pub fn authentificateClient(_: *Server, connection: *lib.Connection) !void {
    var stream = connection.stream;
    _ = try stream.readRequestUntilComplete(&connection.request);
    var auth_object: AuthRequest = .{};
    _ = try connection.request.jsonDeserialize(@TypeOf(auth_object), &auth_object);
    log.info("received '{s}'", .{connection.request.last_req.?});
    const auth_answer: AuthResponse = .{
        .head = .{
            .host = .server,
            .tag = .auth,
            .status = .ok,
            .timestamp = std.time.timestamp(),
        },
        .token = 1,
    };
    log.info("sending '{s}'", .{connection.response.jsonSerialize(auth_answer) catch unreachable});

    _ = try stream.sendResponse(&connection.response);
}
