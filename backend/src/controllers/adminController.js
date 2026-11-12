import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { Op } from 'sequelize';
import {
  Payment, AppConfig, User, Booking, CompanionProfile,
  Conversation, Message, Report, OtpCode
} from '../models/index.js';
import { getSmtpCredentials, createTransporter, sendOtpEmail } from '../config/email.js';
import { successResponse, errorResponse } from '../utils/responseHelper.js';

/**
 * Admin Login endpoint.
 * Authenticates email + password.
 * Seeds initial admin user if none exists.
 */
export const adminLogin = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return errorResponse(res, 'Email and password are required', 400);
    }

    const adminEmail = process.env.ADMIN_EMAIL || 'admin@connect4people.com';
    const adminDefaultPass = process.env.ADMIN_PASSWORD || 'Admin@2026!';

    // Check if an admin exists
    let admin = await User.findOne({ where: { email: email.toLowerCase().trim() } });

    // Seed default admin if requested email matches and no admin user exists
    if (!admin && email.toLowerCase().trim() === adminEmail.toLowerCase().trim()) {
      const hash = await bcrypt.hash(adminDefaultPass, 10);
      admin = await User.create({
        name: 'Platform Administrator',
        email: adminEmail.toLowerCase().trim(),
        password_hash: hash,
        role: 'admin',
        is_verified: true,
        is_payment_verified: true,
        is_active: true
      });
      console.log(`[Admin] Default admin created: ${adminEmail}`);
    }

    if (!admin) {
      return errorResponse(res, 'Invalid admin credentials', 401);
    }

    if (admin.role !== 'admin') {
      return errorResponse(res, 'Access denied. Account is not an administrator.', 403);
    }

    // Compare password
    const isMatch = admin.password_hash
      ? await bcrypt.compare(password, admin.password_hash)
      : password === adminDefaultPass;

    if (!isMatch) {
      return errorResponse(res, 'Invalid admin credentials', 401);
    }

    // Generate JWT
    const token = jwt.sign(
      { id: admin.id, email: admin.email, role: 'admin' },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    return successResponse(res, 'Admin login successful', {
      token,
      user: {
        id: admin.id,
        name: admin.name,
        email: admin.email,
        role: admin.role
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * List pending payment claims.
 */
export const getPendingPayments = async (req, res, next) => {
  try {
    const { type, page = 1, limit = 50 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const where = { status: 'claimed' };
    if (type) where.payment_type = type;

    const { count, rows: payments } = await Payment.findAndCountAll({
      where,
      include: [
        { model: User, as: 'user', attributes: ['id', 'name', 'email', 'phone', 'avatar_url'] },
        { model: Booking, as: 'booking', attributes: ['id', 'booking_type', 'start_time', 'end_time', 'amount', 'platform_fee', 'companion_payout'] }
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
 * List all payments with optional status filter.
 */
export const listAllPayments = async (req, res, next) => {
  try {
    const { status, type, page = 1, limit = 50 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const where = {};
    if (status) where.status = status;
    if (type) where.payment_type = type;

    const { count, rows: payments } = await Payment.findAndCountAll({
      where,
      include: [
        { model: User, as: 'user', attributes: ['id', 'name', 'email', 'phone', 'avatar_url'] },
        { model: Booking, as: 'booking', attributes: ['id', 'booking_type', 'amount', 'platform_fee', 'companion_payout'] }
      ],
      order: [['created_at', 'DESC']],
      limit: parseInt(limit),
      offset
    });

    return successResponse(res, 'All payments retrieved', {
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

    // For booking payments, update associated booking to 'confirmed'
    if (payment.payment_type === 'booking' && payment.booking_id) {
      await Booking.update(
        { status: 'confirmed' },
        { where: { id: payment.booking_id } }
      );
    }

    return successResponse(res, 'Payment verified successfully', payment);
  } catch (error) {
    next(error);
  }
};

/**
 * Reject a payment claim.
 */
export const rejectPayment = async (req, res, next) => {
  try {
    const payment = await Payment.findByPk(req.params.id);

    if (!payment) {
      return errorResponse(res, 'Payment not found', 404);
    }

    await payment.update({ status: 'rejected' });
    return successResponse(res, 'Payment rejected', payment);
  } catch (error) {
    next(error);
  }
};

/**
 * Get all app_config entries.
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
 * Update app_config entries.
 */
export const updateConfig = async (req, res, next) => {
  try {
    const updates = req.body;

    for (const [key, value] of Object.entries(updates)) {
      await AppConfig.upsert({ key, value: String(value), updated_at: new Date() });
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
 * List all users with optional filters and search.
 */
export const listUsers = async (req, res, next) => {
  try {
    const { search, role, is_companion, is_active, page = 1, limit = 50 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);
    const where = {};

    if (search) {
      where[Op.or] = [
        { name: { [Op.iLike]: `%${search}%` } },
        { email: { [Op.iLike]: `%${search}%` } },
        { phone: { [Op.iLike]: `%${search}%` } },
        { city: { [Op.iLike]: `%${search}%` } }
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
 * Create a new user or companion directly by admin.
 */
export const createUser = async (req, res, next) => {
  try {
    const {
      name, email, phone, city, gender, bio, role = 'user',
      is_companion = false, is_verified = false, is_payment_verified = false,
      hourly_rate, event_rate, tagline, avatar_url
    } = req.body;

    if (!email) {
      return errorResponse(res, 'Email is required', 400);
    }

    const existing = await User.findOne({ where: { email } });
    if (existing) {
      return errorResponse(res, 'A user with this email already exists', 409);
    }

    const user = await User.create({
      name,
      email,
      phone,
      city,
      gender,
      bio,
      role,
      avatar_url: avatar_url || null,
      is_companion: Boolean(is_companion),
      is_verified: Boolean(is_verified),
      is_payment_verified: Boolean(is_payment_verified),
      is_active: true
    });

    if (is_companion) {
      await CompanionProfile.create({
        user_id: user.id,
        hourly_rate: hourly_rate || 500,
        event_rate: event_rate || 2000,
        tagline: tagline || '',
        is_listed: true
      });
    }

    const fullUser = await User.findByPk(user.id, {
      include: [{ model: CompanionProfile, as: 'companion_profile' }]
    });

    return successResponse(res, 'User created successfully', fullUser, 201);
  } catch (error) {
    next(error);
  }
};

/**
 * Update any user profile and companion details.
 */
export const updateUser = async (req, res, next) => {
  try {
    const { id } = req.params;
    const user = await User.findByPk(id);

    if (!user) {
      return errorResponse(res, 'User not found', 404);
    }

    const {
      name, phone, city, gender, bio, role,
      is_companion, is_verified, is_payment_verified, is_active,
      hourly_rate, event_rate, tagline, is_listed, avatar_url
    } = req.body;

    const updates = {};
    if (name !== undefined) updates.name = name;
    if (phone !== undefined) updates.phone = phone;
    if (city !== undefined) updates.city = city;
    if (gender !== undefined) updates.gender = gender;
    if (bio !== undefined) updates.bio = bio;
    if (role !== undefined) updates.role = role;
    if (avatar_url !== undefined) updates.avatar_url = avatar_url;
    if (is_companion !== undefined) updates.is_companion = is_companion;
    if (is_verified !== undefined) updates.is_verified = is_verified;
    if (is_payment_verified !== undefined) updates.is_payment_verified = is_payment_verified;
    if (is_active !== undefined) updates.is_active = is_active;

    await user.update(updates);

    if (user.is_companion) {
      let profile = await CompanionProfile.findOne({ where: { user_id: user.id } });
      const compUpdates = {};
      if (hourly_rate !== undefined) compUpdates.hourly_rate = hourly_rate;
      if (event_rate !== undefined) compUpdates.event_rate = event_rate;
      if (tagline !== undefined) compUpdates.tagline = tagline;
      if (is_listed !== undefined) compUpdates.is_listed = is_listed;

      if (profile) {
        await profile.update(compUpdates);
      } else {
        await CompanionProfile.create({
          user_id: user.id,
          hourly_rate: hourly_rate || 500,
          event_rate: event_rate || 2000,
          tagline: tagline || '',
          is_listed: is_listed !== undefined ? is_listed : true
        });
      }
    }

    const refreshed = await User.findByPk(user.id, {
      include: [{ model: CompanionProfile, as: 'companion_profile' }]
    });

    return successResponse(res, 'User updated successfully', refreshed);
  } catch (error) {
    next(error);
  }
};

/**
 * Delete a user profile and all related records.
 */
export const deleteUser = async (req, res, next) => {
  try {
    const { id } = req.params;
    const user = await User.findByPk(id);

    if (!user) {
      return errorResponse(res, 'User not found', 404);
    }

    // Cascade delete
    await CompanionProfile.destroy({ where: { user_id: id } });
    await user.destroy();

    return successResponse(res, 'User deleted successfully');
  } catch (error) {
    next(error);
  }
};

/**
 * List all bookings across the platform.
 */
export const listAllBookings = async (req, res, next) => {
  try {
    const { status, page = 1, limit = 50 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const where = {};
    if (status) where.status = status;

    const { count, rows: bookings } = await Booking.findAndCountAll({
      where,
      include: [
        { model: User, as: 'client', attributes: ['id', 'name', 'email', 'phone', 'avatar_url'] },
        { model: User, as: 'companion', attributes: ['id', 'name', 'email', 'phone', 'avatar_url'] },
        { model: Payment, as: 'payments' }
      ],
      order: [['created_at', 'DESC']],
      limit: parseInt(limit),
      offset
    });

    return successResponse(res, 'Bookings retrieved', {
      bookings,
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
 * Update booking status manually by admin.
 */
export const updateBookingStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const booking = await Booking.findByPk(id);
    if (!booking) {
      return errorResponse(res, 'Booking not found', 404);
    }

    await booking.update({ status });
    return successResponse(res, 'Booking updated successfully', booking);
  } catch (error) {
    next(error);
  }
};

/**
 * List all conversations across all users with message count and latest message.
 */
export const listAllConversations = async (req, res, next) => {
  try {
    const conversations = await Conversation.findAll({
      include: [
        { model: User, as: 'user1', attributes: ['id', 'name', 'email', 'avatar_url'] },
        { model: User, as: 'user2', attributes: ['id', 'name', 'email', 'avatar_url'] },
        {
          model: Message,
          as: 'messages',
          limit: 1,
          order: [['created_at', 'DESC']]
        }
      ],
      order: [['last_message_at', 'DESC']]
    });

    return successResponse(res, 'Conversations retrieved', conversations);
  } catch (error) {
    next(error);
  }
};

/**
 * Get all messages in a specific conversation for admin inspection.
 */
export const getConversationMessages = async (req, res, next) => {
  try {
    const { id } = req.params;

    const conversation = await Conversation.findByPk(id, {
      include: [
        { model: User, as: 'user1', attributes: ['id', 'name', 'email'] },
        { model: User, as: 'user2', attributes: ['id', 'name', 'email'] }
      ]
    });

    if (!conversation) {
      return errorResponse(res, 'Conversation not found', 404);
    }

    const messages = await Message.findAll({
      where: { conversation_id: id },
      include: [
        { model: User, as: 'sender', attributes: ['id', 'name', 'email', 'avatar_url'] }
      ],
      order: [['created_at', 'ASC']]
    });

    return successResponse(res, 'Messages retrieved', { conversation, messages });
  } catch (error) {
    next(error);
  }
};

/**
 * Delete a specific message by ID.
 */
export const deleteMessage = async (req, res, next) => {
  try {
    const { id } = req.params;
    const message = await Message.findByPk(id);

    if (!message) {
      return errorResponse(res, 'Message not found', 404);
    }

    await message.destroy();
    return successResponse(res, 'Message deleted successfully');
  } catch (error) {
    next(error);
  }
};

/**
 * List all user reports.
 */
export const listReports = async (req, res, next) => {
  try {
    const reports = await Report.findAll({
      include: [
        { model: User, as: 'reporter', attributes: ['id', 'name', 'email'] },
        { model: User, as: 'reported', attributes: ['id', 'name', 'email'] }
      ],
      order: [['created_at', 'DESC']]
    });

    return successResponse(res, 'Reports retrieved', reports);
  } catch (error) {
    next(error);
  }
};

/**
 * Update report status / add admin notes.
 */
export const updateReport = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status, notes } = req.body;

    const report = await Report.findByPk(id);
    if (!report) {
      return errorResponse(res, 'Report not found', 404);
    }

    const updates = {};
    if (status) updates.status = status;
    if (notes !== undefined) updates.notes = notes;

    await report.update(updates);
    return successResponse(res, 'Report updated successfully', report);
  } catch (error) {
    next(error);
  }
};

/**
 * Get dashboard statistics.
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

    const totalConversations = await Conversation.count();
    const totalReports = await Report.count({ where: { status: 'pending' } });

    return successResponse(res, 'Dashboard stats retrieved', {
      totalUsers,
      activeCompanions,
      totalBookings,
      completedBookings,
      totalRevenue,
      pendingPayments,
      totalConversations,
      pendingReports: totalReports
    });
  } catch (error) {
    next(error);
  }
};

/**
 * List recent OTP verification codes for platform inspection.
 */
export const listRecentOtps = async (req, res, next) => {
  try {
    const otps = await OtpCode.findAll({
      order: [['created_at', 'DESC']],
      limit: 25
    });
    return successResponse(res, 'Recent OTP codes retrieved', otps);
  } catch (error) {
    next(error);
  }
};

/**
 * Diagnostic endpoint to check live email environment variables and SMTP connection.
 */
export const getEmailStatus = async (req, res, next) => {
  try {
    const { user, pass } = getSmtpCredentials();
    const hasResend = Boolean(process.env.RESEND_API_KEY);
    const hasSmtpUser = Boolean(user);
    const hasSmtpPass = Boolean(pass);

    const detectedKeys = [];
    [
      'SMTP_USER', 'SMTP_USERNAME', 'EMAIL_USER', 'EMAIL_USERNAME', 'GMAIL_USER', 'GMAIL', 'EMAIL',
      'SMTP_PASS', 'SMTP_PASSWORD', 'EMAIL_PASS', 'EMAIL_PASSWORD', 'GMAIL_PASS', 'GMAIL_APP_PASSWORD',
      'APP_PASSWORD', 'APP_PASS', 'RESEND_API_KEY'
    ].forEach(k => {
      if (process.env[k]) detectedKeys.push(k);
    });

    let smtpVerification = null;
    if (hasSmtpUser && hasSmtpPass) {
      try {
        const transporter = createTransporter();
        await transporter.verify();
        smtpVerification = { success: true, message: 'SMTP connection verified successfully' };
      } catch (err) {
        smtpVerification = {
          success: false,
          error: err.message,
          code: err.code,
          hint: err.code === 'ETIMEDOUT'
            ? 'Render Free Tier blocks outbound SMTP traffic on ports 25, 465, and 587. To send real emails from Render, add RESEND_API_KEY or upgrade the Render instance.'
            : (err.message.includes('Username and Password not accepted')
              ? 'Gmail App Password invalid or 2FA not enabled on this Google account.'
              : err.message)
        };
      }
    }

    return successResponse(res, 'Email status diagnostics retrieved', {
      hasResend,
      hasSmtpUser,
      smtpUser: user ? `${user.substring(0, 3)}***@${user.split('@')[1] || ''}` : null,
      hasSmtpPass,
      passLength: pass ? pass.length : 0,
      detectedKeys,
      smtpVerification
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Test endpoint to dispatch a test email to any address.
 */
export const testSendEmail = async (req, res, next) => {
  try {
    const { email } = req.body;
    if (!email) {
      return errorResponse(res, 'Target email is required', 400);
    }
    const result = await sendOtpEmail(email, '998877', 'signup');
    return successResponse(res, 'Email dispatch result', result);
  } catch (error) {
    next(error);
  }
};
