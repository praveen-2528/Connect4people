import { Router } from 'express';
import { body, query } from 'express-validator';
import {
  createBooking, listBookings, getBookingDetail,
  acceptBooking, declineBooking, cancelBooking,
  completeBooking, submitReview
} from '../controllers/bookingController.js';
import { getBookingPaymentInfo, claimBookingPayment } from '../controllers/paymentController.js';
import { validate } from '../middleware/validate.js';
import { authenticate } from '../middleware/auth.js';

const router = Router();

// All booking routes require authentication
router.use(authenticate);

/**
 * @route POST /api/bookings
 * @desc Create a new booking
 */
router.post(
  '/',
  [
    body('companion_id').isUUID().withMessage('Valid companion_id is required'),
    body('booking_type').optional().isString().withMessage('booking_type must be a string'),
    body('start_time').isISO8601().withMessage('start_time must be a valid ISO date'),
    body('end_time').isISO8601().withMessage('end_time must be a valid ISO date'),
    body('location').optional().isString().trim().withMessage('location must be a string'),
    body('notes').optional().isString().withMessage('notes must be a string')
  ],
  validate,
  createBooking
);

/**
 * @route GET /api/bookings
 * @desc List my bookings with filters
 */
router.get(
  '/',
  [
    query('role').optional().isIn(['client', 'companion']).withMessage('role must be client or companion'),
    query('status').optional().isIn(['pending', 'accepted', 'ongoing', 'completed', 'cancelled', 'declined']).withMessage('Invalid status'),
    query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
    query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be 1-100')
  ],
  validate,
  listBookings
);

/**
 * @route GET /api/bookings/:id
 * @desc Get booking detail
 */
router.get('/:id', getBookingDetail);

/**
 * @route PUT /api/bookings/:id/accept
 * @desc Companion accepts a booking
 */
router.put('/:id/accept', acceptBooking);

/**
 * @route PUT /api/bookings/:id/decline
 * @desc Companion declines a booking
 */
router.put('/:id/decline', declineBooking);

/**
 * @route PUT /api/bookings/:id/cancel
 * @desc Either party cancels a booking
 */
router.put('/:id/cancel', cancelBooking);

/**
 * @route PUT /api/bookings/:id/complete
 * @desc Mark booking as completed
 */
router.put('/:id/complete', completeBooking);

/**
 * @route POST /api/bookings/:id/review
 * @desc Submit a review for a completed booking
 */
router.post(
  '/:id/review',
  [
    body('rating').isInt({ min: 1, max: 5 }).withMessage('Rating must be 1-5'),
    body('comment').optional().isString().withMessage('Comment must be a string')
  ],
  validate,
  submitReview
);

/**
 * @route GET /api/bookings/:id/payment-info
 * @desc Get booking payment QR + amount
 */
router.get('/:id/payment-info', getBookingPaymentInfo);

/**
 * @route POST /api/bookings/:id/payment/claim
 * @desc Client claims they've paid for a booking
 */
router.post(
  '/:id/payment/claim',
  [
    body('method').optional().isString().withMessage('method must be a string'),
    body('reference_note').optional().isString().withMessage('reference_note must be a string')
  ],
  validate,
  claimBookingPayment
);

export default router;
