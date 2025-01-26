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

    var client = lib.Client.init(gpa.allocator(), .{
        .non_blocking = true,
        .tickrate = 60,
        .timeout = 200,
    });
    defer client.deinit();

    const address = try net.Address.parseIp("127.0.0.1", 8080);
    var stream = try lib.Client.Stream.init(address, client.options);

    var clock: lib.Clock = .init(&client.clock, client.options.timeout, 1000);
    stream.connectOrTimeout(&clock) catch |err| {
        std.log.err("error {!}", .{err});
        return;
    };
    clock.reset();

    var request = lib.ClientRequest.init(gpa.allocator());
    defer request.deinit();

    try request.jsonSerialize(prot.Authentification.Request{
        .header = .{
            .host = .client,
            .tag = .auth,
            .status = .confirm,
            .timestamp = clock.now(),
        },
        .pass = "abcdefg",
    });

    _ = stream.sendRequestOrTimeout(&request, &clock) catch |err| {
        std.log.err("error {!}", .{err});
    };
    clock.reset();

    var response = lib.ClientResponse.init(gpa.allocator());
    defer response.deinit();

    _ = stream.readIntoResponseOrTimeout(&response, &clock) catch |err| {
        std.log.err("error {!}", .{err});
    };

    var answer = lib.Authentification.Response{};
    try response.jsonDeserialize(lib.Authentification.Response, &answer);
    std.debug.print("{}", .{answer});
}
