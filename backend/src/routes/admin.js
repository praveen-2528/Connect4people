import { Router } from 'express';
import {
  getPendingPayments, verifyPayment, rejectPayment,
  getConfig, updateConfig, listUsers, getStats
} from '../controllers/adminController.js';
import { authenticate, isAdmin } from '../middleware/auth.js';

const router = Router();

// All admin routes require authentication + admin role
router.use(authenticate, isAdmin);

/**
 * @route GET /api/admin/payments/pending
 * @desc List pending payment claims
 */
router.get('/payments/pending', getPendingPayments);

/**
 * @route PUT /api/admin/payments/:id/verify
 * @desc Verify a payment claim
 */
router.put('/payments/:id/verify', verifyPayment);

/**
 * @route PUT /api/admin/payments/:id/reject
 * @desc Reject a payment claim
 */
router.put('/payments/:id/reject', rejectPayment);

/**
 * @route GET /api/admin/config
 * @desc Get all app_config entries
 */
router.get('/config', getConfig);

/**
 * @route PUT /api/admin/config
 * @desc Update app_config entries
 */
router.put('/config', updateConfig);

/**
 * @route GET /api/admin/users
 * @desc List all users with filters
 */
router.get('/users', listUsers);

/**
 * @route GET /api/admin/stats
 * @desc Get dashboard statistics
 */
router.get('/stats', getStats);

export default router;
