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
    if (self.envp.get("SSP_PONG_BALL_RADIUS")) |value| {
        self.pong_config.ball_radius = parseOfFallback(u32, "SSP_PONG_BALL_RADIUS", value, PongOptions.default.ball_radius);
    } else {
        logFallback("SSP_PONG_BALL_RADIUS", u32, PongOptions.default.ball_radius);
    }

    if (self.envp.get("SSP_PONG_BALL_SPEED")) |value| {
        self.pong_config.ball_speed = parseOfFallback(u32, "SSP_PONG_BALL_SPEED", value, PongOptions.default.ball_speed);
    } else {
        logFallback("SSP_PONG_BALL_SPEED", u32, PongOptions.default.ball_speed);
    }

    if (self.envp.get("SSP_PONG_BOARD_WIDTH")) |value| {
        self.pong_config.board_width = parseOfFallback(u32, "SSP_PONG_BOARD_WIDTH", value, PongOptions.default.board_width);
    } else {
        logFallback("SSP_PONG_BOARD_WIDTH", u32, PongOptions.default.board_width);
    }

    if (self.envp.get("SSP_PONG_BOARD_HEIGHT")) |value| {
        self.pong_config.board_height = parseOfFallback(u32, "SSP_PONG_BOARD_HEIGHT", value, PongOptions.default.board_height);
    } else {
        logFallback("SSP_PONG_BOARD_HEIGHT", u32, PongOptions.default.board_height);
    }

    if (self.envp.get("SSP_PONG_PADDLE_WIDTH")) |value| {
        self.pong_config.paddle_width = parseOfFallback(u32, "SSP_PONG_PADDLE_WIDTH", value, PongOptions.default.paddle_width);
    } else {
        logFallback("SSP_PONG_PADDLE_WIDTH", u32, PongOptions.default.paddle_width);
    }

    if (self.envp.get("SSP_PONG_PADDLE_HEIGHT")) |value| {
        self.pong_config.paddle_height = parseOfFallback(u32, "SSP_PONG_PADDLE_HEIGHT", value, PongOptions.default.paddle_height);
    } else {
        logFallback("SSP_PONG_PADDLE_HEIGHT", u32, PongOptions.default.paddle_height);
    }

    if (self.envp.get("SSP_PONG_PADDLE_SPEED")) |value| {
        self.pong_config.paddle_speed = parseOfFallback(u32, "SSP_PONG_PADDLE_SPEED", value, PongOptions.default.paddle_speed);
    } else {
        logFallback("SSP_PONG_PADDLE_SPEED", u32, PongOptions.default.paddle_speed);
    }

    if (self.envp.get("SSP_SERV_MAXCONN")) |value| {
        self.serv_config.maxconn = parseOfFallback(u8, "SSP_SERV_MAXCONN", value, ServerOptions.default.maxconn);
    } else {
        logFallback("SSP_SERV_MAXCONN", u8, ServerOptions.default.maxconn);
    }

    if (self.envp.get("SSP_SERV_P1TOK")) |value| {
        self.serv_config.client1_id = parseOfFallback(u8, "SSP_SERV_P1TOK", value, ServerOptions.default.client1_id);
    } else {
        logFallback("SSP_SERV_P1TOK", u8, ServerOptions.default.client1_id);
    }

    if (self.envp.get("SSP_SERV_P2TOK")) |value| {
        self.serv_config.client2_id = parseOfFallback(u8, "SSP_SERV_P2TOK", value, ServerOptions.default.client2_id);
    } else {
        logFallback("SSP_SERV_P2TOK", u8, ServerOptions.default.client2_id);
    }

    if (self.envp.get("SSP_SERV_TICKRATE")) |value| {
        self.serv_config.tickrate = parseOfFallback(u16, "SSP_SERV_TICKRATE", value, ServerOptions.default.tickrate);
    } else {
        logFallback("SSP_SERV_TICKRATE", u16, ServerOptions.default.tickrate);
    }

    if (self.envp.get("SSP_SERV_BIND_IP")) |value| {
        self.serv_config.ip = value;
    } else {
        self.serv_config.ip = ServerOptions.default.ip;
        logFallback("SSP_SERV_BIND_IP", []const u8, ServerOptions.default.ip);
    }

    if (self.envp.get("SSP_SERV_ON_PORT")) |value| {
        self.serv_config.port = parseOfFallback(u16, "SSP_SERV_ON_PORT", value, ServerOptions.default.port);
    } else {
        logFallback("SSP_SERV_ON_PORT", u16, ServerOptions.default.port);
    }

    if (self.envp.get("SSP_SERV_HEADLESS")) |value| {
        self.serv_config.headless = if (compare(value, "true")) true else false;
    }
}

fn parseOfFallback(comptime T: type, key: []const u8, buff: []const u8, fallback: T) T {
    return std.fmt.parseInt(T, buff, 10) catch |err| {
        std.log.err("error while parsing value associated with '{s}' : {!}", .{ key, err });
        std.log.info("fallback to : '{any}'", .{fallback});
        return fallback;
    };
}

fn logFallback(key: []const u8, comptime T: type, fallback: T) void {
    log.warn("No value specified for '{s}', defaulting to value : {any}", .{ key, fallback });
}

fn compare(s1: []const u8, s2: []const u8) bool {
    return std.mem.eql(u8, s1, s2);
}
