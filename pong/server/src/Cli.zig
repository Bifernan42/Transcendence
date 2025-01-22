// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Cli.zig                                            :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/22 20:51:03 by pollivie          #+#    #+#             //
//   Updated: 2025/01/22 20:51:04 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const builtin = @import("builtin");
const std = @import("std");
const io = std.io;
const log = std.log;
const mem = std.mem;
const json = std.json;
const heap = std.heap;
const process = std.process;
const Config = @import("Config.zig");

const Cli = @This();

argv: process.ArgIterator = undefined,

pub const default: Cli = .{
    .argv = undefined,
};

pub fn init(arena: *std.heap.ArenaAllocator) !Cli {
    return .{
        .argv = try process.argsWithAllocator(arena.allocator()),
    };
}

pub fn deinit(self: *Cli) void {
    self.argv.deinit();
}

pub fn parseOrDefault(_: *Cli) !Config {
    const cfg: Config = .default;

    return cfg;
}
