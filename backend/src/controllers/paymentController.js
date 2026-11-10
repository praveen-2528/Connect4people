import { Op } from 'sequelize';
import { Payment, AppConfig, User, Booking } from '../models/index.js';
import { successResponse, errorResponse } from '../utils/responseHelper.js';

/**
 * Get registration fee info and QR code URL from app_config.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const getRegistrationInfo = async (req, res, next) => {
  try {
    const feeConfig = await AppConfig.findByPk('registration_fee');
    const qrConfig = await AppConfig.findByPk('upi_qr_url');
    const upiConfig = await AppConfig.findByPk('upi_id');

    return successResponse(res, 'Registration info retrieved', {
      registration_fee: feeConfig ? feeConfig.value : '299',
      upi_qr_url: qrConfig ? qrConfig.value : '',
      upi_id: upiConfig ? upiConfig.value : ''
    });
  } catch (error) {
    next(error);
  }
};

/**
 * User claims they have paid the registration fee.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const claimRegistrationPayment = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { method, reference_note } = req.body;

    // Check if user already has a pending/claimed/verified registration payment
    const existing = await Payment.findOne({
      where: {
        user_id: userId,
        payment_type: 'registration',
        status: { [Op.in]: ['claimed', 'verified'] }
      }
    });

    if (existing) {
      if (existing.status === 'verified') {
        return errorResponse(res, 'Registration payment already verified', 409);
      }
      return errorResponse(res, 'Registration payment claim already pending', 409);
    }

    // Get registration fee from config
    const feeConfig = await AppConfig.findByPk('registration_fee');
    const amount = feeConfig ? parseFloat(feeConfig.value) : 299;

    const payment = await Payment.create({
      user_id: userId,
      payment_type: 'registration',
      amount,
      status: 'claimed',
      method: method || 'upi',
      reference_note: reference_note || null,
      claimed_at: new Date()
    });

    return successResponse(res, 'Registration payment claimed successfully', payment, 201);
  } catch (error) {
    next(error);
  }
};

/**
 * Check if user's registration payment is verified.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const getRegistrationStatus = async (req, res, next) => {
  try {
    const user = await User.findByPk(req.user.id, {
      attributes: ['id', 'is_payment_verified']
    });

    const payment = await Payment.findOne({
      where: {
        user_id: req.user.id,
        payment_type: 'registration'
      },
      order: [['created_at', 'DESC']]
    });

    return successResponse(res, 'Registration status retrieved', {
      is_payment_verified: user.is_payment_verified,
      payment: payment || null
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get booking payment QR and amount info.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const getBookingPaymentInfo = async (req, res, next) => {
  try {
    const booking = await Booking.findOne({
      where: {
        id: req.params.id,
        [Op.or]: [
          { client_id: req.user.id },
          { companion_id: req.user.id }
        ]
      }
    });

    if (!booking) {
      return errorResponse(res, 'Booking not found', 404);
    }

    const qrConfig = await AppConfig.findByPk('upi_qr_url');
    const upiConfig = await AppConfig.findByPk('upi_id');

    return successResponse(res, 'Booking payment info retrieved', {
      booking_id: booking.id,
      amount: booking.amount,
      upi_qr_url: qrConfig ? qrConfig.value : '',
      upi_id: upiConfig ? upiConfig.value : ''
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Client claims they have paid for a booking.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const claimBookingPayment = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const bookingId = req.params.id;
    const { method, reference_note } = req.body;

    const booking = await Booking.findOne({
      where: { id: bookingId, client_id: userId }
    });

    if (!booking) {
      return errorResponse(res, 'Booking not found', 404);
    }

    // Check for existing claimed/verified payment
    const existing = await Payment.findOne({
      where: {
        booking_id: bookingId,
        user_id: userId,
        payment_type: 'booking',
        status: { [Op.in]: ['claimed', 'verified'] }
      }
    });

    if (existing) {
      if (existing.status === 'verified') {
        return errorResponse(res, 'Booking payment already verified', 409);
      }
      return errorResponse(res, 'Booking payment claim already pending', 409);
    }

    const payment = await Payment.create({
      user_id: userId,
      booking_id: bookingId,
      payment_type: 'booking',
      amount: booking.amount,
      status: 'claimed',
      method: method || 'upi',
      reference_note: reference_note || null,
      claimed_at: new Date()
    });

    return successResponse(res, 'Booking payment claimed successfully', payment, 201);
  } catch (error) {
    next(error);
  }
};
