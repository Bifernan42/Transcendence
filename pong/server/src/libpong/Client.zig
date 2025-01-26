// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Client.zig                                         :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/26 11:21:13 by pollivie          #+#    #+#             //
//   Updated: 2025/01/26 11:21:13 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const root = @import("root.zig");
const json = std.json;
const net = std.net;
const fmt = std.fmt;
const mem = std.mem;
const heap = std.heap;
const posix = std.posix;
const Request = @import("Request.zig");
const Response = @import("Response.zig");
const Stream = root.Stream;
const InternalState = @import("protocol.zig").ClientInfo;
const Client = @This();
const AuthRequest = root.protocol.Auth.Request;
const AuthResponse = root.protocol.Auth.Response;

allocator: mem.Allocator,
address: net.Address,
socket: posix.socket_t,
state: InternalState,
request: Request,
response: Response,

pub const ClientOptions = struct {
    ip: []const u8 = "127.0.0.1",
    port: u16 = 8080,
    state: ?InternalState = null,
    role: []const u8 = "player1",
    name: []const u8 = "pierre",
    pass: []const u8 = "password",
};

pub fn init(allocator: mem.Allocator, options: ClientOptions) !Client {
    const address = try net.Address.parseIp(options.ip, options.port);
    return .{
        .allocator = allocator,
        .address = address,
        .socket = -1,
        .state = options.state orelse .{},
        .request = Request.init(allocator),
        .response = Response.init(allocator),
    };
}

pub fn deinit(self: *Client) void {
    if (self.socket != -1) {
        posix.close(self.socket);
    }
    self.request.deinit();
    self.response.deinit();
    self.* = undefined;
}

pub const OpenSocketOptions = struct {
    reuse_port: bool = true,
    reuse_addr: bool = true,
    blocking: bool = false,
    sock_type: u32 = posix.SOCK.STREAM,
    sock_prot: u32 = posix.IPPROTO.TCP,
};

pub fn openSocket(self: *Client, options: OpenSocketOptions) !void {
    const socket_type = if (options.blocking) options.sock_type else options.sock_type | posix.SOCK.NONBLOCK;
    const socket = try posix.socket(
        self.address.any.family,
        socket_type,
        options.sock_prot,
    );
    errdefer posix.close(socket);

    const reuse_port: u32 = if (options.reuse_port) posix.SO.REUSEPORT else 0;
    const reuse_addr: u32 = if (options.reuse_addr) posix.SO.REUSEADDR else 0;
    const reuse = reuse_port | reuse_addr;

    try posix.setsockopt(
        socket,
        posix.SOL.SOCKET,
        reuse,
        &mem.toBytes(@as(c_int, 1)),
    );
    self.socket = socket;
}

pub fn sendAuthRequest(self: *Client) !void {
    defer self.request.clearLastRetainRemaining();
    const req_object: AuthRequest = .{
        .head = .{
            .host = .client,
            .tag = .auth,
            .status = .ok,
            .timestamp = std.time.timestamp(),
        },
        .role = self.state.role,
        .name = self.state.name,
        .pass = self.state.pass,
    };
    std.debug.print("sending : '{!s}'", .{self.request.jsonSerialize(req_object)});
    var stream = self.openStream();
    _ = try stream.sendRequest(&self.request);
}

pub fn getAuthResponse(self: *Client) !void {
    defer self.response.clearLastRetainRemaining();
    var res_object: AuthResponse = .{};
    var stream = self.openStream();
    while (!try stream.readResponseUntilComplete(&self.response)) {
        try self.response.jsonDeserialize(@TypeOf(res_object), &res_object);
        std.debug.print("received : '{s}'", .{res_object});

        switch (res_object.head.status) {
            .none => return,
            .ok => self.state.tokn = res_object.token,
            .err => self.state.curr_state = .disconnnected,
        }
    }
}

pub fn connectSocket(self: *Client) !void {
    try posix.connect(self.socket, &self.address.any, self.address.getOsSockLen());
}

pub fn openStream(self: *Client) Stream {
    return Stream.init(self.address, self.socket);
}
