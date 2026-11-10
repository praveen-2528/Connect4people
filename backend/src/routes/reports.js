import { Router } from 'express';
import { body } from 'express-validator';
import { createReport } from '../controllers/reportController.js';
import { validate } from '../middleware/validate.js';
import { authenticate } from '../middleware/auth.js';

const router = Router();

/**
 * @route POST /api/reports
 * @desc Create a report against a user
 */
router.post(
  '/',
  authenticate,
  [
    body('reported_user_id').isUUID().withMessage('Valid reported_user_id is required'),
    body('booking_id').optional().isUUID().withMessage('booking_id must be a valid UUID'),
    body('reason').notEmpty().isString().withMessage('Reason is required'),
    body('description').optional().isString().withMessage('Description must be a string')
  ],
  validate,
  createReport
);

export default router;
