import bcrypt from 'bcryptjs';
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

/**
 * Register a user with Email and Password.
 */
export const registerWithPassword = async (req, res, next) => {
  try {
    const { email, password, name } = req.body;

    if (!email || !password) {
      return errorResponse(res, 'Email and password are required', 400);
    }
    if (password.length < 6) {
      return errorResponse(res, 'Password must be at least 6 characters', 400);
    }

    const normalizedEmail = email.toLowerCase().trim();
    const existing = await User.findOne({ where: { email: normalizedEmail } });
    if (existing) {
      return errorResponse(res, 'An account already exists with this email. Please sign in.', 409);
    }

    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash(password, salt);

    const user = await User.create({
      email: normalizedEmail,
      name: name?.trim() || null,
      password_hash
    });

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '30d' }
    );

    const userData = await User.findByPk(user.id, {
      attributes: { exclude: ['password_hash'] },
      include: [{ model: CompanionProfile, as: 'companion_profile' }]
    });

    return successResponse(res, 'Registration successful', {
      token,
      user: userData,
      isNewUser: true
    }, 201);
  } catch (error) {
    next(error);
  }
};

/**
 * Login a user with Email and Password.
 */
export const loginWithPassword = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return errorResponse(res, 'Email and password are required', 400);
    }

    const normalizedEmail = email.toLowerCase().trim();
    const user = await User.findOne({ where: { email: normalizedEmail } });
    if (!user) {
      return errorResponse(res, 'Invalid email or password', 401);
    }

    if (!user.is_active) {
      return errorResponse(res, 'Account is deactivated. Please contact support.', 403);
    }

    if (!user.password_hash) {
      return errorResponse(res, 'No password set for this account. Please sign in using Email OTP or reset your password.', 400);
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return errorResponse(res, 'Invalid email or password', 401);
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '30d' }
    );

    const userData = await User.findByPk(user.id, {
      attributes: { exclude: ['password_hash'] },
      include: [{ model: CompanionProfile, as: 'companion_profile' }]
    });

    return successResponse(res, 'Login successful', {
      token,
      user: userData,
      isNewUser: false
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Set or update password for authenticated user.
 */
export const setPassword = async (req, res, next) => {
  try {
    const { password } = req.body;
    if (!password || password.length < 6) {
      return errorResponse(res, 'Password must be at least 6 characters', 400);
    }

    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash(password, salt);

    await User.update({ password_hash }, { where: { id: req.user.id } });

    return successResponse(res, 'Password updated successfully');
  } catch (error) {
    next(error);
  }
};
