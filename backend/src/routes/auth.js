import { Router } from 'express';
import { body } from 'express-validator';
import {
  sendOtp,
  verifyOtp,
  refreshToken,
  registerWithPassword,
  loginWithPassword,
  setPassword
} from '../controllers/authController.js';
import { validate } from '../middleware/validate.js';
import { authenticate } from '../middleware/auth.js';

const router = Router();

/**
 * @route POST /api/auth/register
 * @desc Register with email and password
 */
router.post(
  '/register',
  [
    body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
  ],
  validate,
  registerWithPassword
);

/**
 * @route POST /api/auth/login
 * @desc Sign in with email and password
 */
router.post(
  '/login',
  [
    body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
    body('password').notEmpty().withMessage('Password is required')
  ],
  validate,
  loginWithPassword
);

/**
 * @route POST /api/auth/set-password
 * @desc Set password for authenticated user
 */
router.post(
  '/set-password',
  authenticate,
  [
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
  ],
  validate,
  setPassword
);

/**
 * @route POST /api/auth/send-otp
 * @desc Generate and send a 6-digit OTP to the provided email
 */
router.post(
  '/send-otp',
  [
    body('email').isEmail().normalizeEmail().withMessage('Valid email is required')
  ],
  validate,
  sendOtp
);

/**
 * @route POST /api/auth/verify-otp
 * @desc Verify OTP, create user if new, return JWT + user data
 */
router.post(
  '/verify-otp',
  [
    body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
    body('code').isLength({ min: 6, max: 6 }).isNumeric().withMessage('OTP must be a 6-digit number')
  ],
  validate,
  verifyOtp
);

/**
 * @route POST /api/auth/refresh
 * @desc Refresh JWT token for authenticated user
 */
router.post('/refresh', authenticate, refreshToken);

export default router;
