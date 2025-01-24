const std = @import("std");
const Protocol = @import("Protocol.zig").Protocol;
const posix = std.posix;
const json = std.json;

pub const Client = struct {
    authenticated: bool = false,
    name: []const u8,
    role: []const u8,
    time_ms: i64 = 0,

    pub fn init(name: []const u8, role: []const u8) Client {
        return .{
            .authenticated = false,
            .name = name,
            .role = role,
            .time_ms = 0,
        };
    }

    pub fn makeAuthRequest(self: Client, allocator: std.mem.Allocator) ![]const u8 {
        const auth_request: Protocol.Handshake.Request = .{
            .client_id = self.name,
            .timestamp = std.time.timestamp(),
        };
        return try std.fmt.allocPrint(allocator, "{s}\n", .{auth_request});
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

        posix.nanosleep(0, 1_000_000);
        total_read += rbytes;

        if (std.mem.indexOfScalar(u8, buff[0..total_read], Protocol.Delimiter[0]) != null) {
            std.log.info("found message boundary.", .{});
            return buff[0..total_read];
        }
    }
    return error.InvalidData;
}

pub fn main() !void {
    const page_allocator = std.heap.page_allocator;
    var arena_allocator: std.heap.ArenaAllocator = .init(page_allocator);
    defer arena_allocator.deinit();

    const allocator = arena_allocator.allocator();
    const address = try std.net.Address.parseIp("127.0.0.1", 8080);

    const tpe: u32 = posix.SOCK.STREAM;
    const protocol = posix.IPPROTO.TCP;
    const socket = try posix.socket(address.any.family, tpe, protocol);
    defer posix.close(socket);

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

    var client: Client = .init("P1", "player1");
    const request = try client.makeAuthRequest(allocator);
    defer allocator.free(request);
    std.log.info("{} : request ready : {s}.", .{ address, request });

    // Append delimiter to the message
    const message_with_delimiter = try allocator.alloc(u8, request.len + 1);
    defer allocator.free(message_with_delimiter);
    @memcpy(message_with_delimiter[0..request.len], request);
    message_with_delimiter[request.len] = Protocol.Delimiter[0];

    // Send request
    std.log.info("{} : sending request. : {s}", .{ address, request });
    try sendMessage(socket, message_with_delimiter);

    // Receive response
    std.log.info("{} : waiting for response.", .{address});
    const response = try receiveMessage(socket, allocator);
    defer allocator.free(response);
    std.debug.print("{} : received: {s}\n", .{ address, response });
}
