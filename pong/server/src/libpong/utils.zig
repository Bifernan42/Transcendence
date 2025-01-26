// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   utils.zig                                          :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/26 10:51:32 by pollivie          #+#    #+#             //
//   Updated: 2025/01/26 10:51:33 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");

pub fn Pair(comptime T1: type, comptime T2: type) type {
    return struct {
        pub const T: type = @TypeOf(Self);
        const Self = @This();
        first: T1,
        second: T2,

        pub fn init(first: T1, second: T2) Self {
            return .{
                .first = first,
                .second = second,
            };
        }

        pub fn deinit(self: *Self) void {
            if (std.meta.hasMethod(T1, "deinit")) {
                self.first.deinit();
            }
            if (std.meta.hasMethod(T2, "deinit")) {
                self.second.deinit();
            }
        }
    };
}

pub const Clock = struct {
    timer: *std.time.Timer,
    begin: usize,
    end: usize,
    timeout: usize,
    tick: usize,

    pub fn init(timer: *std.time.Timer, timeout_ms: usize, tick: ?usize) Clock {
        const begin = timer.read();
        const timeout = timeout_ms * std.time.ns_per_ms;
        return .{
            .timer = timer,
            .begin = begin,
            .end = begin + timeout,
            .timeout = timeout,
            .tick = if (tick) |v| v else 1_000_000,
        };
    }

    pub fn didTimeout(self: *Clock) bool {
        const lap = self.begin + self.timer.read();
        return lap >= self.end;
    }

    pub fn reset(self: *Clock) void {
        self.begin = self.timer.read();
        self.end = self.begin + self.timeout;
    }

    pub fn sleep(self: *const Clock) void {
        std.posix.nanosleep(0, self.tick);
    }

    pub fn now(_: *const Clock) i64 {
        return std.time.milliTimestamp();
    }
};
