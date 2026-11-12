import { Router } from 'express';
import {
  adminLogin,
  getPendingPayments,
  listAllPayments,
  verifyPayment,
  rejectPayment,
  getConfig,
  updateConfig,
  listUsers,
  createUser,
  updateUser,
  deleteUser,
  listAllBookings,
  updateBookingStatus,
  listAllConversations,
  getConversationMessages,
  deleteMessage,
  listReports,
  updateReport,
  getStats,
  listRecentOtps,
  getEmailStatus,
  testSendEmail
} from '../controllers/adminController.js';
import { authenticate, isAdmin } from '../middleware/auth.js';

const router = Router();

// Public Admin Login Route
router.post('/login', adminLogin);

// Protected routes below require Authentication + Admin role
router.use(authenticate, isAdmin);

// Dashboard Overview Statistics
router.get('/stats', getStats);

// User & Profile Management
router.get('/users', listUsers);
router.post('/users', createUser);
router.put('/users/:id', updateUser);
router.delete('/users/:id', deleteUser);

// Bookings Management
router.get('/bookings', listAllBookings);
router.put('/bookings/:id/status', updateBookingStatus);

// Payments Management
router.get('/payments', listAllPayments);
router.get('/payments/pending', getPendingPayments);
router.put('/payments/:id/verify', verifyPayment);
router.put('/payments/:id/reject', rejectPayment);

// Conversations & Chat Monitoring
router.get('/conversations', listAllConversations);
router.get('/conversations/:id/messages', getConversationMessages);
router.delete('/messages/:id', deleteMessage);

// Reports & Safety
router.get('/reports', listReports);
router.put('/reports/:id', updateReport);

// System & Fee Configuration
router.get('/config', getConfig);
router.put('/config', updateConfig);

// Recent OTP Codes Monitor
router.get('/otps', listRecentOtps);

// Email Delivery & SMTP Diagnostics
router.get('/email-status', getEmailStatus);
router.post('/test-email', testSendEmail);

export default router;
