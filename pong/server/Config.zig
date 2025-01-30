// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Config.zig                                         :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/30 14:39:43 by pollivie          #+#    #+#             //
//   Updated: 2025/01/30 14:39:44 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const lib = @import("libpong");
const process = std.process;
const heap = std.heap;
const mem = std.mem;
const net = std.net;
const log = std.log;
const posix = std.posix;
const ServerOptions = @import("Server.zig").ServerOptions;
const PongOptions = @import("Pong.zig").PongOptions;
const AiDifficulty = @import("Pong.zig").AiDifficulty;

const Config = @This();

envp: process.EnvMap,
pong_config: PongOptions,
serv_config: ServerOptions,

pub fn init(allocator: mem.Allocator) !Config {
    return .{
        .envp = try process.getEnvMap(allocator),
        .pong_config = .{},
        .serv_config = .{},
    };
}

pub fn deinit(self: *Config) void {
    self.envp.deinit();
}

pub fn parse(self: *Config) !void {
    if (self.envp.get("SSP_PONG_AI_DIFFICULTY")) |value| {
        inline for (.{ "recruit", "normal", "commando", "veteran" }, std.meta.tags(AiDifficulty)) |name, tag| {
            if (compare(name, value)) {
                self.pong_config.ai_difficulty = tag;
            }
        }

        // if (compare(value, "recruit")) {
        //     self.pong_config.ai_difficulty = .recruit;
        // }else if (compare(value, "recruit"))
    }
}

fn compare(s1: []const u8, s2: []const u8) bool {
    return std.mem.eql(u8, s1, s2);
}

// const EnvironmentVariables = .{
//     "SSP_PONG_AI_DIFFICULTY",
//     "SSP_PONG_BALL_RADIUS",
//     "SSP_PONG_BALL_SPEED",
//     "SSP_PONG_BOARD_WIDTH",
//     "SSP_PONG_BOARD_HEIGHT",
//     "SSP_PONG_PADDLE_WIDTH",
//     "SSP_PONG_PADDLE_HEIGHT",
//     "SSP_PONG_PADDLE_SPEED",
//     "SSP_SERV_MAXCONN",
//     "SSP_SERV_P1_NAME",
//     "SSP_SERV_P2_NAME",
//     "SSP_SERV_TCKRATE",
//     "SSP_SERV_LOG_LVL",
//     "SSP_SERV_MAXBUFF",
//     "SSP_SERV_BIND_IP",
//     "SSP_SERV_ON_PORT",
//     "SSP_SERV_TIMEOUT",
//     "SSP_SERV_MAXRTRY",
//     "SSP_SERV_IPPROTO",
//     "SSP_SERV_NONBLCK",
// };
