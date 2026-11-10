import { Op } from 'sequelize';
import { Conversation, Message, User } from '../models/index.js';
import { successResponse, errorResponse } from '../utils/responseHelper.js';

/**
 * List conversations for the current user with last message preview.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const listConversations = async (req, res, next) => {
  try {
    const userId = req.user.id;

    const conversations = await Conversation.findAll({
      where: {
        [Op.or]: [
          { user1_id: userId },
          { user2_id: userId }
        ]
      },
      include: [
        { model: User, as: 'user1', attributes: ['id', 'name', 'avatar_url'] },
        { model: User, as: 'user2', attributes: ['id', 'name', 'avatar_url'] },
        {
          model: Message,
          as: 'messages',
          limit: 1,
          order: [['created_at', 'DESC']],
          attributes: ['id', 'content', 'message_type', 'sender_id', 'is_read', 'created_at']
        }
      ],
      order: [['last_message_at', 'DESC NULLS LAST']]
    });

    // Transform to include "other user" and "last message" fields
    const transformed = conversations.map((conv) => {
      const convo = conv.toJSON();
      const otherUser = convo.user1.id === userId ? convo.user2 : convo.user1;
      const lastMessage = convo.messages && convo.messages.length > 0 ? convo.messages[0] : null;

      return {
        id: convo.id,
        other_user: otherUser,
        last_message: lastMessage,
        last_message_at: convo.last_message_at,
        booking_id: convo.booking_id,
        created_at: convo.created_at
      };
    });

    return successResponse(res, 'Conversations retrieved successfully', transformed);
  } catch (error) {
    next(error);
  }
};

/**
 * Get paginated messages for a conversation (newest first).
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const getMessages = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const conversationId = req.params.id;
    const { page = 1, limit = 50 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    // Verify user is a participant
    const conversation = await Conversation.findOne({
      where: {
        id: conversationId,
        [Op.or]: [
          { user1_id: userId },
          { user2_id: userId }
        ]
      }
    });

    if (!conversation) {
      return errorResponse(res, 'Conversation not found', 404);
    }

    const { count, rows: messages } = await Message.findAndCountAll({
      where: { conversation_id: conversationId },
      include: [
        { model: User, as: 'sender', attributes: ['id', 'name', 'avatar_url'] }
      ],
      order: [['created_at', 'DESC']],
      limit: parseInt(limit),
      offset
    });

    // Mark unread messages from the other user as read
    await Message.update(
      { is_read: true },
      {
        where: {
          conversation_id: conversationId,
          sender_id: { [Op.ne]: userId },
          is_read: false
        }
      }
    );

    return successResponse(res, 'Messages retrieved successfully', {
      messages,
      pagination: {
        total: count,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(count / parseInt(limit))
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Create a new conversation between two users.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const createConversation = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { user_id, booking_id } = req.body;

    if (userId === user_id) {
      return errorResponse(res, 'Cannot create a conversation with yourself', 400);
    }

    // Check if the other user exists
    const otherUser = await User.findByPk(user_id);
    if (!otherUser) {
      return errorResponse(res, 'User not found', 404);
    }

    // Check if conversation already exists between these two users
    const existingConvo = await Conversation.findOne({
      where: {
        [Op.or]: [
          { user1_id: userId, user2_id: user_id },
          { user1_id: user_id, user2_id: userId }
        ]
      }
    });

    if (existingConvo) {
      return successResponse(res, 'Conversation already exists', existingConvo);
    }

    const conversation = await Conversation.create({
      user1_id: userId,
      user2_id: user_id,
      booking_id: booking_id || null
    });

    const fullConvo = await Conversation.findByPk(conversation.id, {
      include: [
        { model: User, as: 'user1', attributes: ['id', 'name', 'avatar_url'] },
        { model: User, as: 'user2', attributes: ['id', 'name', 'avatar_url'] }
      ]
    });

    return successResponse(res, 'Conversation created successfully', fullConvo, 201);
  } catch (error) {
    next(error);
  }
};
