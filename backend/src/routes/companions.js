import { Router } from 'express';
import { query } from 'express-validator';
import { listCompanions, getCompanionDetail, getCompanionReviews } from '../controllers/companionController.js';
import { validate } from '../middleware/validate.js';

const router = Router();

/**
 * @route GET /api/companions
 * @desc List companions with filters, pagination, sorting
 */
router.get(
  '/',
  [
    query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
    query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be 1-100'),
    query('min_price').optional().isDecimal().withMessage('min_price must be a number'),
    query('max_price').optional().isDecimal().withMessage('max_price must be a number'),
    query('min_rating').optional().isDecimal().withMessage('min_rating must be a number')
  ],
  validate,
  listCompanions
);

/**
 * @route GET /api/companions/:id
 * @desc Get companion detail with photos and reviews
 */
router.get('/:id', getCompanionDetail);

/**
 * @route GET /api/companions/:id/reviews
 * @desc Get paginated reviews for a companion
 */
router.get(
  '/:id/reviews',
  [
    query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
    query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be 1-100')
  ],
  validate,
  getCompanionReviews
);

export default router;
