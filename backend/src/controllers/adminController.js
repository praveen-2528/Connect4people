import { Op, fn, col } from 'sequelize';
import { Payment, AppConfig, User, Booking, CompanionProfile } from '../models/index.js';
import { successResponse, errorResponse } from '../utils/responseHelper.js';

/**
 * List pending payment claims (both registration and booking).
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const getPendingPayments = async (req, res, next) => {
  try {
    const { type, page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const where = { status: 'claimed' };
    if (type) where.payment_type = type;

    const { count, rows: payments } = await Payment.findAndCountAll({
      where,
      include: [
        { model: User, as: 'user', attributes: ['id', 'name', 'email', 'phone', 'avatar_url'] },
        { model: Booking, as: 'booking', attributes: ['id', 'booking_type', 'start_time', 'end_time'] }
      ],
      order: [['claimed_at', 'ASC']],
      limit: parseInt(limit),
      offset
    });

    return successResponse(res, 'Pending payments retrieved', {
      payments,
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
 * Verify a payment claim.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const verifyPayment = async (req, res, next) => {
  try {
    const payment = await Payment.findByPk(req.params.id);

    if (!payment) {
      return errorResponse(res, 'Payment not found', 404);
    }

    if (payment.status !== 'claimed') {
      return errorResponse(res, `Payment is already ${payment.status}`, 400);
    }

    await payment.update({
      status: 'verified',
      verified_at: new Date()
    });

    // For registration payments, also set user.is_payment_verified = true
    if (payment.payment_type === 'registration') {
      await User.update(
        { is_payment_verified: true },
        { where: { id: payment.user_id } }
      );
    }

    return successResponse(res, 'Payment verified successfully', payment);
  } catch (error) {
    next(error);
  }
};

/**
 * Reject a payment claim.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const rejectPayment = async (req, res, next) => {
  try {
    const payment = await Payment.findByPk(req.params.id);

    if (!payment) {
      return errorResponse(res, 'Payment not found', 404);
    }

    if (payment.status !== 'claimed') {
      return errorResponse(res, `Payment is already ${payment.status}`, 400);
    }

    await payment.update({ status: 'rejected' });

    return successResponse(res, 'Payment rejected', payment);
  } catch (error) {
    next(error);
  }
};

/**
 * Get all app_config entries.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const getConfig = async (req, res, next) => {
  try {
    const configs = await AppConfig.findAll();
    const configMap = {};
    configs.forEach((c) => { configMap[c.key] = c.value; });

    return successResponse(res, 'Config retrieved', configMap);
  } catch (error) {
    next(error);
  }
};

/**
 * Update app_config entries (key-value pairs).
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const updateConfig = async (req, res, next) => {
  try {
    const updates = req.body; // expects { key: value, ... }

    for (const [key, value] of Object.entries(updates)) {
      await AppConfig.upsert({ key, value, updated_at: new Date() });
    }

    const configs = await AppConfig.findAll();
    const configMap = {};
    configs.forEach((c) => { configMap[c.key] = c.value; });

    return successResponse(res, 'Config updated successfully', configMap);
  } catch (error) {
    next(error);
  }
};

/**
 * List all users with optional filters.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const listUsers = async (req, res, next) => {
  try {
    const { search, role, is_companion, is_active, page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);
    const where = {};

    if (search) {
      where[Op.or] = [
        { name: { [Op.iLike]: `%${search}%` } },
        { email: { [Op.iLike]: `%${search}%` } },
        { phone: { [Op.iLike]: `%${search}%` } }
      ];
    }
    if (role) where.role = role;
    if (is_companion !== undefined) where.is_companion = is_companion === 'true';
    if (is_active !== undefined) where.is_active = is_active === 'true';

    const { count, rows: users } = await User.findAndCountAll({
      where,
      attributes: { exclude: ['password_hash'] },
      include: [
        { model: CompanionProfile, as: 'companion_profile', required: false }
      ],
      order: [['created_at', 'DESC']],
      limit: parseInt(limit),
      offset
    });

    return successResponse(res, 'Users retrieved', {
      users,
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
 * Get dashboard statistics.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const getStats = async (req, res, next) => {
  try {
    const totalUsers = await User.count();
    const activeCompanions = await User.count({
      where: { is_companion: true, is_active: true }
    });
    const totalBookings = await Booking.count();
    const completedBookings = await Booking.count({
      where: { status: 'completed' }
    });

    // Total revenue = sum of platform_fee from completed bookings
    const revenueResult = await Booking.sum('platform_fee', {
      where: { status: 'completed' }
    });
    const totalRevenue = revenueResult || 0;

    // Pending payments count
    const pendingPayments = await Payment.count({
      where: { status: 'claimed' }
    });

    return successResponse(res, 'Dashboard stats retrieved', {
      totalUsers,
      activeCompanions,
      totalBookings,
      completedBookings,
      totalRevenue,
      pendingPayments
    });
  } catch (error) {
    next(error);
  }
};
