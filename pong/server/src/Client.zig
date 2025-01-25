// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Client.zig                                         :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/22 21:28:18 by pollivie          #+#    #+#             //
//   Updated: 2025/01/22 21:28:19 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const net = std.net;
const log = std.log;
const mem = std.mem;
const json = std.json;
const heap = std.heap;
const time = std.time;
const posix = std.posix;
const process = std.process;
const io = std.io;
const builtin = @import("builtin");
const Protocol = @import("Protocol.zig");

pub const State = enum {
    connected,
    disconnected,
    authentificated,
    waiting,
    playing,
    done,
};

pub const Client = struct {
    gpa: mem.Allocator,
    clock: time.Timer,
    address: net.Address,
    socket: posix.socket_t,
    state: State,
    buffer: Protocol.Buffer(u8),

    pub fn init(gpa: mem.Allocator, address: net.Address, socket: posix.socket_t) Client {
        return .{
            .gpa = gpa,
            .clock = time.Timer.start() catch unreachable,
            .address = address,
            .socket = socket,
            .state = .connected,
            .buffer = Protocol.Buffer(u8).init(gpa),
        };
    }

    pub fn deinit(self: *Client) void {
        self.buffer.deinit();
    }

    pub fn transition(self: *Client, state: State) void {
        self.state = state;
    }

    pub fn readUntilDelimiter(self: *Client) !bool {
        var read_buffer: [1024]u8 = undefined;
        var total_bytes: usize = 0;
        var rbytes: usize = 0;
        while (true) {
            if (mem.containsAtLeast(u8, self.buffer.slice(), 1, Protocol.Delimiter)) {
                return true;
            }

            rbytes = posix.recv(self.socket, read_buffer[total_bytes..], 0) catch |err| {
                log.debug("posix.recv --> {!}", .{err});
                switch (err) {
                    posix.RecvFromError.WouldBlock => continue,
                    posix.RecvFromError.ConnectionResetByPeer => {
                        self.transition(.disconnected);
                        _ = self.clock.lap();
                    },
                    else => return err,
                }
            };

            total_bytes += rbytes;
            if (rbytes == 0) {
                return true;
            } else {
                try self.buffer.pushSliceBack(total_bytes[total_bytes..rbytes]);
            }
        }
    }

    pub fn sendMessage(self: *Client, msg: []const u8) !bool {
        var total_sent: usize = 0;
        var sbytes: usize = 0;
        while (true) {
            sbytes = posix.send(self.socket, msg[total_sent..], 0) catch |err| switch (err) {
                error.WouldBlock => continue,
                error.NetworkUnreachable, error.NetworkSubsystemFailed, error.ConnectionResetByPeer => {
                    self.transition(.disconnected);
                    return false;
                },
                else => return err,
            };

            total_sent += sbytes;

            if (total_sent == msg.len) {
                return true;
            }
        }
    }

    pub fn getMessage(self: *Client, arena: mem.Allocator) ?[]const u8 {
        const index: usize = mem.indexOf(u8, self.buffer.slice(), Protocol.Delimiter) orelse return null;
        return self.buffer.popSliceFront(arena, index) catch return null;
    }

    pub fn getHandshakeRequest(client: *Client) Protocol.Request(.handshake) {
        return Protocol.Request(.handshake).init(client.gpa);
    }

    pub fn getConfigRequest(client: *Client) Protocol.Request(.config) {
        return Protocol.Request(.config).init(client.gpa);
    }

    pub fn getUpdateRequest(client: *Client) Protocol.Request(.update) {
        return Protocol.Request(.update).init(client.gpa);
    }

    pub fn getAcknowledgementRequest(client: *Client) Protocol.Request(.acknowledgement) {
        return Protocol.Request(.acknowledgement).init(client.gpa);
    }

    pub fn getFailureRequest(client: *Client) Protocol.Request(.failure) {
        return Protocol.Request(.failure).init(client.gpa);
    }

    pub fn getHandshakeResponse(client: *Client) Protocol.Response(.handshake) {
        return Protocol.Response(.handshake).init(client.gpa);
    }

    pub fn getConfigResponse(client: *Client) Protocol.Response(.config) {
        return Protocol.Response(.config).init(client.gpa);
    }

    pub fn getUpdateResponse(client: *Client) Protocol.Response(.update) {
        return Protocol.Response(.update).init(client.gpa);
    }

    pub fn getAcknowledgementResponse(client: *Client) Protocol.Response(.acknowledgement) {
        return Protocol.Response(.acknowledgement).init(client.gpa);
    }
    pub fn getFailureResponse(client: *Client) Protocol.Response(.failure) {
        return Protocol.Response(.failure).init(client.gpa);
    }
};
