// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   root.zig                                           :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/30 10:09:15 by pollivie          #+#    #+#             //
//   Updated: 2025/01/30 10:09:15 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");

pub const rg = @import("raygui");
pub const rl = @import("raygui");

pub const Ball = @import("pong/Ball.zig").Ball;
pub const Board = @import("pong/Board.zig").Board;
pub const Game = @import("pong/Game.zig").Game;
pub const GameKind = @import("pong/Game.zig").Kind;
pub const GameRules = @import("pong/Game.zig").Rules;
pub const Player = @import("pong/Player.zig").Player;
pub const PlayerRole = @import("pong/Player.zig").Role;
pub const PlayerAction = @import("pong/Player.zig").Action;
pub const PlayerStatus = @import("pong/Player.zig").Status;
pub const PlayerMove = @import("pong/Player.zig").Move;
