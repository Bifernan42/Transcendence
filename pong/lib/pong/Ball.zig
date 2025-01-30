// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Ball.zig                                           :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/30 11:07:40 by pollivie          #+#    #+#             //
//   Updated: 2025/01/30 11:07:40 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");

pub const Ball = packed struct(u128) {
    position: rl.Vector2,
    velocity: rl.Vector2,
};
