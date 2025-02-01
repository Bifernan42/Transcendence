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
const Pong = @import("Pong.zig");
const PongOptions = @import("Pong.zig").PongOptions;

const Config = @This();

envp: process.EnvMap,

pub fn init(allocator: mem.Allocator) !Config {
    return .{
        .envp = try process.getEnvMap(allocator),
    };
}

pub fn deinit(self: *Config) void {
    self.envp.deinit();
}

pub fn parseEnviromentVariables(self: *Config) PongOptions {
    const envp = self.envp;
    var options: PongOptions = .init();

    if (envp.get("SSP_BOARD_WIDTH")) |value| {
        options.board_width = parseOrSetDefault("SSP_BOARD_WIDTH", u16, value, PongOptions.default.board_width);
    } else {
        options.board_width = warnAndSetDefault("SSP_BOARD_WIDTH", u16, PongOptions.default.board_width);
    }

    if (envp.get("SSP_BOARD_HEIGHT")) |value| {
        options.board_height = parseOrSetDefault("SSP_BOARD_HEIGHT", u16, value, PongOptions.default.board_height);
    } else {
        options.board_height = warnAndSetDefault("SSP_BOARD_HEIGHT", u16, PongOptions.default.board_height);
    }

    if (envp.get("SSP_PADDLE_WIDTH")) |value| {
        options.paddle_width = parseOrSetDefault("SSP_PADDLE_WIDTH", u16, value, PongOptions.default.paddle_width);
    } else {
        options.paddle_width = warnAndSetDefault("SSP_PADDLE_WIDTH", u16, PongOptions.default.paddle_width);
    }

    if (envp.get("SSP_PADDLE_HEIGHT")) |value| {
        options.paddle_height = parseOrSetDefault("SSP_PADDLE_HEIGHT", u16, value, PongOptions.default.paddle_height);
    } else {
        options.paddle_height = warnAndSetDefault("SSP_PADDLE_HEIGHT", u16, PongOptions.default.paddle_height);
    }

    if (envp.get("SSP_PADDLE_SPEED")) |value| {
        options.paddle_speed = parseOrSetDefault("SSP_PADDLE_SPEED", u16, value, PongOptions.default.paddle_speed);
    } else {
        options.paddle_speed = warnAndSetDefault("SSP_PADDLE_SPEED", u16, PongOptions.default.paddle_speed);
    }

    if (envp.get("SSP_BALL_SPEED")) |value| {
        options.ball_speed = parseOrSetDefault("SSP_BALL_SPEED", u16, value, PongOptions.default.ball_speed);
    } else {
        options.ball_speed = warnAndSetDefault("SSP_BALL_SPEED", u16, PongOptions.default.ball_speed);
    }

    if (envp.get("SSP_BALL_RADIUS")) |value| {
        options.ball_radius = parseOrSetDefault("SSP_BALL_RADIUS", u16, value, PongOptions.default.ball_radius);
    } else {
        options.ball_radius = warnAndSetDefault("SSP_BALL_RADIUS", u16, PongOptions.default.ball_radius);
    }

    if (envp.get("SSP_MAX_SCORE")) |value| {
        options.max_score = parseOrSetDefault("SSP_MAX_SCORE", u8, value, PongOptions.default.max_score);
    } else {
        options.max_score = warnAndSetDefault("SSP_MAX_SCORE", u8, PongOptions.default.max_score);
    }

    if (envp.get("SSP_GAME_KIND")) |value| {
        if (std.mem.eql(u8, "local_ai", value)) {
            options.game_kind = .local_ai;
        } else if (std.mem.eql(u8, "local_mp", value)) {
            options.game_kind = .local_mp;
        } else if (std.mem.eql(u8, "remote_mp", value)) {
            options.game_kind = .remote_mp;
        } else {
            log.warn("failed to parse value associated with variable '{s}' because : {s} is invalid. defaults to : {s}", .{ "SSP_GAME_KIND", value, @tagName(PongOptions.default.game_kind) });
            options.game_kind = warnAndSetDefault("SSP_GAME_KIND", Pong.Kind, PongOptions.default.game_kind);
        }
    } else {
        options.game_kind = warnAndSetDefault("SSP_GAME_KIND", Pong.Kind, PongOptions.default.game_kind);
    }

    if (envp.get("SSP_PLAYER1_TOKENID")) |value| {
        options.player1_token = parseOrSetDefault("SSP_PLAYER1_TOKENID", u32, value, PongOptions.default.player1_token);
    } else {
        options.player1_token = warnAndSetDefault("SSP_PLAYER1_TOKENID", u32, PongOptions.default.player1_token);
    }

    if (envp.get("SSP_PLAYER2_TOKENID")) |value| {
        options.player2_token = parseOrSetDefault("SSP_PLAYER2_TOKENID", u32, value, PongOptions.default.player2_token);
    } else {
        options.player2_token = warnAndSetDefault("SSP_PLAYER2_TOKENID", u32, PongOptions.default.player2_token);
    }

    if (envp.get("SSP_SERVER_IP")) |value| {
        options.server_ip = try_ip_first: {
            if (std.net.Address.parseIp(value, 0)) |_| {
                break :try_ip_first value;
            } else |err| {
                log.warn("failed to parse value associated with variable '{s}' because : {!}. defaults to : {s}", .{ "SSP_SERVER_IP", err, PongOptions.default.server_ip });
                break :try_ip_first PongOptions.default.server_ip;
            }
        };
    } else {
        options.server_ip = warnAndSetDefault("SSP_SERVER_IP", []const u8, PongOptions.default.server_ip);
    }

    if (envp.get("SSP_SERVER_PORT")) |value| {
        options.server_port = parseOrSetDefault("SSP_SERVER_PORT", u16, value, PongOptions.default.server_port);
    } else {
        options.server_port = warnAndSetDefault("SSP_SERVER_PORT", u16, PongOptions.default.server_port);
    }

    if (envp.get("SSP_SERVER_TICKRATE")) |value| {
        options.server_tickrate = parseOrSetDefault("SSP_SERVER_TICKRATE", u16, value, PongOptions.default.server_tickrate);
    } else {
        options.server_tickrate = warnAndSetDefault("SSP_SERVER_TICKRATE", u16, PongOptions.default.server_tickrate);
    }

    if (envp.get("SSP_SERVER_CLIENT_MAX")) |value| {
        options.server_client_max = parseOrSetDefault("SSP_SERVER_CLIENT_MAX", u8, value, PongOptions.default.server_client_max);
    } else {
        options.server_client_max = warnAndSetDefault("SSP_SERVER_CLIENT_MAX", u8, PongOptions.default.server_client_max);
    }

    if (envp.get("SSP_SERVER_HEADLESS")) |value| {
        if (std.mem.eql(u8, "true", value)) {
            options.server_headless = true;
        } else if (std.mem.eql(u8, "false", value)) {
            options.server_headless = false;
        } else {
            options.server_headless = warnAndSetDefault("SSP_SERVER_HEADLESS", bool, PongOptions.default.server_headless);
        }
    } else {
        options.server_headless = warnAndSetDefault("SSP_SERVER_HEADLESS", bool, PongOptions.default.server_headless);
    }

    return options;
}

pub fn parseOrSetDefault(varname: []const u8, comptime T: type, value: []const u8, default: T) T {
    return switch (@typeInfo(T)) {
        .float => {
            return std.fmt.parseFloat(T, value) catch |err| {
                log.warn("failed to parse value associated with variable '{s}' because : {!}. defaults to : {d:.2}", .{ varname, err, default });
                return default;
            };
        },
        .int => {
            return std.fmt.parseInt(T, value, 10) catch |err| {
                log.warn("failed to parse value associated with variable '{s}' because : {!}. defaults to : {d}", .{ varname, err, default });
                return default;
            };
        },
        else => @compileError("unsupported type"),
    };
}

pub fn warnAndSetDefault(varname: []const u8, comptime T: type, default: T) T {
    return switch (@typeInfo(T)) {
        .float => {
            log.warn("no value provided for variable '{s}', defaulting to : {d:.2}", .{ varname, default });
            return default;
        },
        .@"enum" => {
            log.warn("no value provided for variable '{s}', defaulting to : {s}", .{ varname, @tagName(default) });
            return default;
        },
        .int => {
            log.warn("no value provided for variable '{s}', defaulting to : {d}", .{ varname, default });
            return default;
        },
        .bool => {
            log.warn("no value provided for variable '{s}', defaulting to : {any}", .{ varname, default });
            return default;
        },
        else => |t| {
            if (std.mem.eql(u8, @typeName(@TypeOf(t)), "[]const u8")) {
                log.warn("no value provided for variable '{s}', defaulting to : {s}", .{ varname, default });
                return default;
            }
            return default;
        },
    };
}
