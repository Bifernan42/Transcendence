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
const Client = lib.Client;

pub fn main() !void {
    var gpa: heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();

    var client = try Client.init(gpa.allocator(), .{
        .ip = "127.0.0.1",
        .port = 8080,
    });
    defer client.deinit();

    try client.openSocket(.{
        .reuse_port = true,
        .reuse_addr = true,
        .blocking = false,
    });

    while (true) {
        client.connectSocket() catch |err| switch (err) {
            error.WouldBlock => continue,
            else => return err,
        };
        break;
    }

    try client.sendAuthRequest();
    try client.getAuthResponse();
}
