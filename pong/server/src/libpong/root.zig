// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   root.zig                                           :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/01/27 10:46:07 by pollivie          #+#    #+#             //
//   Updated: 2025/01/27 10:46:08 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

pub const protocol = @import("protocol.zig");
pub const cli = @import("Cli.zig");
pub const Ball = protocol.Ball;
pub const Board = protocol.Board;
pub const Message = protocol.Message;
pub const Paddle = protocol.Paddle;
pub const Player = protocol.Player;
pub const PlayerMove = protocol.PlayerMove;
pub const PlayerRole = protocol.PlayerRole;
pub const PlayerScore = protocol.PlayerScore;
pub const PlayerState = protocol.PlayerState;
pub const Pong = protocol.Pong;
pub const PongKind = protocol.PongKind;
pub const PongState = protocol.PongState;
pub const Rectangle = protocol.Rectangle;
pub const Surface = protocol.Surface;
pub const Vector2 = protocol.Vector2;
pub const MessageTotalBytes = protocol.MessageTotalBytes;
pub const MessageBackingInteger = protocol.MessageBackingInteger;
pub const MessageBufferCapacity = protocol.MessageBufferCapacity;
pub const State = @import("State.zig").State;
