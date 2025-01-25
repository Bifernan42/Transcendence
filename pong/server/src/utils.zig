// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   utils.zig                                          :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/25 14:00:31 by pollivie          #+#    #+#             //
//   Updated: 2025/01/25 14:00:31 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");

pub fn Pair(comptime T1: type, comptime T2: type) type {
    return struct {
        pub const Self = @This();
        first: T1,
        second: T2,

        pub fn init(first: T1, second: T2) Self {
            return .{
                .first = first,
                .second = second,
            };
        }
    };
}
