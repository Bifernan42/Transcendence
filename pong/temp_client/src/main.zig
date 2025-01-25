const std = @import("std");
const net = std.net;
const Protocol = @import("Protocol.zig");
const Pong = @import("Pong.zig");
const Config = @import("Config.zig");
const Client = @import("Client.zig").Client;
const posix = std.posix;
const json = std.json;

pub const ClientServer = struct {
    config: Config,
    player: Pong.Player,
    movement: ?u8,
    credential: u64,
    buffer: Protocol.Buffer(u8),
    inner: Client,

    pub fn init(allocator: std.mem.Allocator, config: Config, player: Pong.Player, address: net.Address, socket: posix.socket_t) ClientServer {
        return .{
            .config = config,
            .player = player,
            .movement = null,
            .credential = 0,
            .buffer = Protocol.Buffer(u8).init(allocator),
            .inner = Client.init(allocator, address, socket),
        };
    }

    pub fn deinit(self: *ClientServer) void {
        self.client.deinit();
        self.buffer.deinit();
    }

    pub fn makeAuthRequest(self: *ClientServer, gpa: std.mem.Allocator) ![]const u8 {
        const request_object: Protocol.Handshake.Request = .{
            .client_id = self.player.name,
            .timestamp = self.now(),
        };
        var request = self.inner.getHandshakeRequest();
        defer request.deinit();

        request.setRequestObjectOrInvalidate(request_object);
        return try gpa.dupe(u8, request.serialize() catch unreachable);
    }

    pub fn handleAuthResponse(self: *ClientServer, response_buffer: []const u8) !bool {
        var handshake = self.inner.getHandshakeResponse();
        defer handshake.deinit();

        _ = try handshake.appendUntilProtocolDelimiter(response_buffer);
        const response: Protocol.Handshake.Response = try handshake.deserialize();

        if (response.status) {
            self.credential = response.token;
            std.debug.print("{}", .{response});
        }
        return true;
    }

    pub fn now(_: *ClientServer) i64 {
        return std.time.milliTimestamp();
    }
};

fn sendMessage(socket: posix.socket_t, msg: []const u8) !void {
    var written: usize = 0;
    while (written < msg.len) {
        const rbytes = posix.send(socket, msg[written..], 0) catch |err| switch (err) {
            error.WouldBlock => continue,
            else => return err,
        };
        written += rbytes;
    }
}

fn receiveMessage(socket: posix.socket_t, allocator: std.mem.Allocator) ![]const u8 {
    const buff = try allocator.alloc(u8, 4096);
    errdefer allocator.free(buff);

    var total_read: usize = 0;
    while (true) {
        std.debug.print("total_read = {d}.\n", .{total_read});
        const rbytes = posix.recv(socket, buff[total_read..], 0) catch |err| switch (err) {
            error.WouldBlock => continue,
            else => {
                std.log.err("received fatal error : {!}", .{err});
                return err;
            },
        };

        total_read += rbytes;

        if (std.mem.indexOfScalar(u8, buff[0..total_read], Protocol.Delimiter[0]) != null) {
            std.log.info("found message boundary.", .{});
            return buff[0..total_read];
        }
    }
    return error.InvalidData;
}

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();

    var arena_allocator: std.heap.ArenaAllocator = .init(gpa.allocator());
    defer arena_allocator.deinit();

    const allocator = arena_allocator.allocator();
    const address = try std.net.Address.parseIp("127.0.0.1", 8080);

    const tpe: u32 = posix.SOCK.STREAM;
    const protocol = posix.IPPROTO.TCP;
    const socket = try posix.socket(address.any.family, tpe, protocol);
    defer posix.close(socket);
    const nanosleep: u64 = (1_000_000_000 / @as(u64, Config.default.tickrate));

    while (true) {
        if (posix.connect(socket, &address.any, address.getOsSockLen())) {
            break;
        } else |err| {
            switch (err) {
                error.WouldBlock, error.ConnectionPending => continue,
                else => return err,
            }
        }
    }
    std.log.info("{} : connected.", .{address});

    var client: ClientServer = .init(gpa.allocator(), Config.default, Pong.Player.p1, address, socket);
    const request = try client.makeAuthRequest(allocator);
    defer gpa.allocator().free(request);
    std.log.info("{} : request ready : {s}.", .{ address, request });

    // Append delimiter to the message
    const message_with_delimiter = try allocator.alloc(u8, request.len + 1);
    defer allocator.free(message_with_delimiter);
    @memcpy(message_with_delimiter[0..request.len], request);
    message_with_delimiter[request.len] = Protocol.Delimiter[0];

    // Send request
    std.log.info("{} : sending request. : {s}", .{ address, request });
    try sendMessage(socket, message_with_delimiter);
    posix.nanosleep(0, nanosleep);

    // Receive response
    std.log.info("{} : waiting for response.", .{address});
    const response = try receiveMessage(socket, allocator);
    _ = try client.handleAuthResponse(response);
    defer allocator.free(response);
    std.debug.print("{} : received: {s}\n", .{ address, response });
}
