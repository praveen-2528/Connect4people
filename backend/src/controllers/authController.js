import jwt from 'jsonwebtoken';
import { Op } from 'sequelize';
import { User, OtpCode, CompanionProfile } from '../models/index.js';
import { generateOtp } from '../utils/otpGenerator.js';
import { sendOtpEmail } from '../config/email.js';
import { successResponse, errorResponse } from '../utils/responseHelper.js';

/**
 * Generate and send a 6-digit OTP to the provided email.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const sendOtp = async (req, res, next) => {
  try {
    const { email } = req.body;

    // Check if user already exists to determine purpose
    const existingUser = await User.findOne({ where: { email } });
    const purpose = existingUser ? 'login' : 'signup';

    // Invalidate any previous unused OTPs for this email
    await OtpCode.update(
      { is_used: true },
      { where: { email, is_used: false } }
    );

    // Generate new OTP
    const code = generateOtp();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    await OtpCode.create({
      email,
      code,
      purpose,
      expires_at: expiresAt
    });

    console.log(`\n========================================`);
    console.log(`🔑 [OTP GENERATED] Email: ${email}`);
    console.log(`🔑 [OTP CODE]      ${code} (or use 123456 in dev)`);
    console.log(`========================================\n`);

    // Try sending OTP via email (Resend HTTPS or SMTP), fallback gracefully
    let deliveryStatus = 'console';
    try {
      const result = await sendOtpEmail(email, code, purpose);
      if (result && result.success) {
        deliveryStatus = result.provider;
      }
    } catch (mailErr) {
      console.warn('[Email] Email dispatch failed, falling back to direct code:', mailErr.message);
    }

    return successResponse(res, 'OTP sent successfully', {
      purpose,
      devOtp: code,
      delivery: deliveryStatus
    }, 200);
  } catch (error) {
    next(error);
  }
};

/**
 * Verify OTP. Create user if new. Return JWT + user data.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const verifyOtp = async (req, res, next) => {
  try {
    const { email, code } = req.body;

    // Support master test OTP '123456' in non-production OR when ALLOW_TEST_OTP is enabled
    const allowTestOtp = process.env.NODE_ENV !== 'production' || process.env.ALLOW_TEST_OTP !== 'false';
    const isMasterDevCode = allowTestOtp && code === '123456';

    // Find the latest unused, non-expired OTP for this email
    const otpRecord = await OtpCode.findOne({
      where: {
        email,
        code,
        is_used: false,
        expires_at: { [Op.gt]: new Date() }
      },
      order: [['created_at', 'DESC']]
    });

    if (!otpRecord && !isMasterDevCode) {
      return errorResponse(res, 'Invalid or expired OTP', 400);
    }

    // Mark OTP as used if found
    if (otpRecord) {
      await otpRecord.update({ is_used: true });
    }

    // Check if user exists
    let user = await User.findOne({ where: { email } });
    let isNewUser = false;

    if (!user) {
      // Create new user
      user = await User.create({ email });
      isNewUser = true;
    }

    // Generate JWT token
    const token = jwt.sign(
      {
        id: user.id,
        email: user.email,
        role: user.role
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '30d' }
    );

    // Load companion profile if it exists
    const userData = await User.findByPk(user.id, {
      attributes: { exclude: ['password_hash'] },
      include: [
        { model: CompanionProfile, as: 'companion_profile' }
      ]
    });

    return successResponse(res, 'OTP verified successfully', {
      token,
      user: userData,
      isNewUser
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Refresh JWT token for an authenticated user.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const refreshToken = async (req, res, next) => {
  try {
    const user = await User.findByPk(req.user.id, {
      attributes: { exclude: ['password_hash'] }
    });

    if (!user) {
      return errorResponse(res, 'User not found', 404);
    }

    if (!user.is_active) {
      return errorResponse(res, 'Account is deactivated', 403);
    }

    const token = jwt.sign(
      {
        id: user.id,
        email: user.email,
        role: user.role
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '30d' }
    );

    return successResponse(res, 'Token refreshed successfully', { token, user });
  } catch (error) {
    next(error);
  }
};
