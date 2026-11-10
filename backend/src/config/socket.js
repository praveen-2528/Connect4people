import { Server } from 'socket.io';
import jwt from 'jsonwebtoken';
import { Message, Conversation, User } from '../models/index.js';

/**
 * Configure and attach Socket.io to the HTTP server.
 * @param {import('http').Server} server
 * @returns {Server}
 */
export const setupSocket = (server) => {
  const io = new Server(server, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST']
    }
  });

  // JWT Authentication middleware for Socket.io
  io.use((socket, next) => {
    try {
      const token =
        socket.handshake.auth?.token ||
        (socket.handshake.headers?.authorization &&
          socket.handshake.headers.authorization.split(' ')[1]);

      if (!token) {
        return next(new Error('Authentication error: Token required'));
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      socket.user = decoded;
      next();
    } catch (err) {
      next(new Error('Authentication error: Invalid token'));
    }
  });

  io.on('connection', (socket) => {
    const userId = socket.user?.id;
    console.log(`[Socket] User connected: ${userId} (Socket ID: ${socket.id})`);

    // Join personal user room for direct notifications
    if (userId) {
      socket.join(`user_${userId}`);
    }

    // Join a specific conversation room
    socket.on('join_conversation', ({ conversationId }) => {
      if (conversationId) {
        socket.join(`conversation_${conversationId}`);
        console.log(`[Socket] User ${userId} joined conversation_${conversationId}`);
      }
    });

    // Leave a specific conversation room
    socket.on('leave_conversation', ({ conversationId }) => {
      if (conversationId) {
        socket.leave(`conversation_${conversationId}`);
        console.log(`[Socket] User ${userId} left conversation_${conversationId}`);
      }
    });

    // Real-time message sending
    socket.on('send_message', async (data, callback) => {
      try {
        const { conversationId, content, messageType = 'text' } = data;

        if (!conversationId || !content) {
          if (callback) callback({ success: false, error: 'conversationId and content are required' });
          return;
        }

        // Verify user is participant in conversation
        const conversation = await Conversation.findByPk(conversationId);
        if (!conversation) {
          if (callback) callback({ success: false, error: 'Conversation not found' });
          return;
        }

        if (conversation.user1_id !== userId && conversation.user2_id !== userId) {
          if (callback) callback({ success: false, error: 'Unauthorized to post to this conversation' });
          return;
        }

        // Create message in database
        const message = await Message.create({
          conversation_id: conversationId,
          sender_id: userId,
          content,
          message_type: messageType,
          is_read: false
        });

        // Update conversation last_message_at
        await conversation.update({ last_message_at: new Date() });

        // Retrieve message with sender details
        const fullMessage = await Message.findByPk(message.id, {
          include: [{ model: User, as: 'sender', attributes: ['id', 'name', 'avatar_url'] }]
        });

        // Emit message to everyone in the conversation room
        io.to(`conversation_${conversationId}`).emit('new_message', fullMessage);

        // Also notify the recipient's direct room if they might not have the conversation open
        const recipientId = conversation.user1_id === userId ? conversation.user2_id : conversation.user1_id;
        io.to(`user_${recipientId}`).emit('conversation_updated', {
          conversationId,
          message: fullMessage
        });

        if (callback) callback({ success: true, data: fullMessage });
      } catch (err) {
        console.error('[Socket] Error sending message:', err);
        if (callback) callback({ success: false, error: 'Failed to send message' });
      }
    });

    // Typing indicators
    socket.on('typing', ({ conversationId }) => {
      socket.to(`conversation_${conversationId}`).emit('user_typing', {
        userId,
        conversationId
      });
    });

    socket.on('stop_typing', ({ conversationId }) => {
      socket.to(`conversation_${conversationId}`).emit('user_stop_typing', {
        userId,
        conversationId
      });
    });

    // Mark messages as read
    socket.on('mark_read', async ({ conversationId }) => {
      try {
        await Message.update(
          { is_read: true },
          {
            where: {
              conversation_id: conversationId,
              is_read: false,
              sender_id: { [Message.sequelize.Op.ne]: userId }
            }
          }
        );

        socket.to(`conversation_${conversationId}`).emit('messages_read', {
          conversationId,
          readBy: userId
        });
      } catch (err) {
        console.error('[Socket] Error marking messages read:', err);
      }
    });

    socket.on('disconnect', () => {
      console.log(`[Socket] User disconnected: ${userId}`);
    });
  });

  return io;
};

export default setupSocket;
