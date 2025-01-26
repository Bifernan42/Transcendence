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
}
