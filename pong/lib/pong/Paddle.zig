// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Paddle.zig                                         :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/30 11:07:49 by pollivie          #+#    #+#             //
//   Updated: 2025/01/30 11:07:50 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");

pub const Paddle = packed struct(u128) {
    dimension: rl.Rectangle,
};
