import { Router } from 'express';
import { body, query } from 'express-validator';
import { listConversations, getMessages, createConversation } from '../controllers/chatController.js';
import { validate } from '../middleware/validate.js';
import { authenticate } from '../middleware/auth.js';

const router = Router();

// All conversation routes require authentication
router.use(authenticate);

/**
 * @route GET /api/conversations
 * @desc List my conversations with last message preview
 */
router.get('/', listConversations);

/**
 * @route POST /api/conversations
 * @desc Create a new conversation
 */
router.post(
  '/',
  [
    body('user_id').isUUID().withMessage('Valid user_id is required'),
    body('booking_id').optional().isUUID().withMessage('booking_id must be a valid UUID')
  ],
  validate,
  createConversation
);

/**
 * @route GET /api/conversations/:id/messages
 * @desc Get paginated messages for a conversation
 */
router.get(
  '/:id/messages',
  [
    query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
    query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be 1-100')
  ],
  validate,
  getMessages
);

export default router;
