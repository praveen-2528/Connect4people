import { Router } from 'express';
import { body } from 'express-validator';
import {
  getRegistrationInfo, claimRegistrationPayment, getRegistrationStatus
} from '../controllers/paymentController.js';
import { validate } from '../middleware/validate.js';
import { authenticate } from '../middleware/auth.js';

const router = Router();

/**
 * @route GET /api/payments/registration-info
 * @desc Get registration fee amount + QR code URL (public)
 */
router.get('/registration-info', getRegistrationInfo);

/**
 * @route POST /api/payments/registration/claim
 * @desc User claims they've paid registration fee
 */
router.post(
  '/registration/claim',
  authenticate,
  [
    body('method').optional().isString().withMessage('method must be a string'),
    body('reference_note').optional().isString().withMessage('reference_note must be a string')
  ],
  validate,
  claimRegistrationPayment
);

/**
 * @route GET /api/payments/registration/status
 * @desc Check if user's registration payment is verified
 */
router.get('/registration/status', authenticate, getRegistrationStatus);

export default router;
