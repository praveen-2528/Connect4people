import { Op } from 'sequelize';
import { sequelize, Booking, User, CompanionProfile, Review } from '../models/index.js';
import { calculateFees } from '../utils/feeCalculator.js';
import { successResponse, errorResponse } from '../utils/responseHelper.js';

/**
 * Create a new booking.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const createBooking = async (req, res, next) => {
  try {
    const clientId = req.user.id;
    const { companion_id, booking_type, start_time, end_time, location, notes } = req.body;

    // Cannot book yourself
    if (clientId === companion_id) {
      return errorResponse(res, 'You cannot book yourself', 400);
    }

    // Get companion profile for rate
    const companionProfile = await CompanionProfile.findOne({
      where: { user_id: companion_id },
      include: [{ model: User, as: 'user', attributes: ['id', 'is_active', 'is_companion'] }]
    });

    if (!companionProfile) {
      return errorResponse(res, 'Companion not found', 404);
    }

    if (!companionProfile.user.is_active || !companionProfile.user.is_companion) {
      return errorResponse(res, 'Companion is not available', 400);
    }

    // Calculate amount based on booking type and duration
    const startDate = new Date(start_time);
    const endDate = new Date(end_time);
    const durationHours = Math.max(1, Math.ceil((endDate - startDate) / (1000 * 60 * 60)));

    let totalAmount;
    if (booking_type === 'event') {
      totalAmount = parseFloat(companionProfile.event_rate || companionProfile.hourly_rate) * durationHours;
    } else {
      totalAmount = parseFloat(companionProfile.hourly_rate) * durationHours;
    }

    const { amount, platformFee, companionPayout } = calculateFees(totalAmount);

    const booking = await Booking.create({
      client_id: clientId,
      companion_id,
      booking_type,
      start_time: startDate,
      end_time: endDate,
      location,
      notes,
      amount,
      platform_fee: platformFee,
      companion_payout: companionPayout,
      status: 'pending'
    });

    const fullBooking = await Booking.findByPk(booking.id, {
      include: [
        { model: User, as: 'client', attributes: ['id', 'name', 'avatar_url'] },
        { model: User, as: 'companion', attributes: ['id', 'name', 'avatar_url'] }
      ]
    });

    return successResponse(res, 'Booking created successfully', fullBooking, 201);
  } catch (error) {
    next(error);
  }
};

/**
 * List bookings for the current user with role and status filters.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const listBookings = async (req, res, next) => {
  try {
    const { role, status, page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);
    const where = {};

    if (role === 'client') {
      where.client_id = req.user.id;
    } else if (role === 'companion') {
      where.companion_id = req.user.id;
    } else {
      where[Op.or] = [
        { client_id: req.user.id },
        { companion_id: req.user.id }
      ];
    }

    if (status) {
      where.status = status;
    }

    const { count, rows: bookings } = await Booking.findAndCountAll({
      where,
      include: [
        { model: User, as: 'client', attributes: ['id', 'name', 'avatar_url'] },
        { model: User, as: 'companion', attributes: ['id', 'name', 'avatar_url'] }
      ],
      order: [['created_at', 'DESC']],
      limit: parseInt(limit),
      offset
    });

    return successResponse(res, 'Bookings retrieved successfully', {
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
 * Get booking detail by ID.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const getBookingDetail = async (req, res, next) => {
  try {
    const booking = await Booking.findOne({
      where: {
        id: req.params.id,
        [Op.or]: [
          { client_id: req.user.id },
          { companion_id: req.user.id }
        ]
      },
      include: [
        { model: User, as: 'client', attributes: ['id', 'name', 'avatar_url', 'phone'] },
        { model: User, as: 'companion', attributes: ['id', 'name', 'avatar_url', 'phone'] },
        { model: Review, as: 'reviews' }
      ]
    });

    if (!booking) {
      return errorResponse(res, 'Booking not found', 404);
    }

    return successResponse(res, 'Booking details retrieved successfully', booking);
  } catch (error) {
    next(error);
  }
};

/**
 * Companion accepts a booking.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const acceptBooking = async (req, res, next) => {
  try {
    const booking = await Booking.findOne({
      where: { id: req.params.id, companion_id: req.user.id, status: 'pending' }
    });

    if (!booking) {
      return errorResponse(res, 'Booking not found or cannot be accepted', 404);
    }

    await booking.update({ status: 'accepted' });

    return successResponse(res, 'Booking accepted successfully', booking);
  } catch (error) {
    next(error);
  }
};

/**
 * Companion declines a booking.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const declineBooking = async (req, res, next) => {
  try {
    const booking = await Booking.findOne({
      where: { id: req.params.id, companion_id: req.user.id, status: 'pending' }
    });

    if (!booking) {
      return errorResponse(res, 'Booking not found or cannot be declined', 404);
    }

    await booking.update({ status: 'declined' });

    return successResponse(res, 'Booking declined successfully', booking);
  } catch (error) {
    next(error);
  }
};

/**
 * Either party cancels a booking.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const cancelBooking = async (req, res, next) => {
  try {
    const booking = await Booking.findOne({
      where: {
        id: req.params.id,
        [Op.or]: [
          { client_id: req.user.id },
          { companion_id: req.user.id }
        ],
        status: { [Op.in]: ['pending', 'accepted'] }
      }
    });

    if (!booking) {
      return errorResponse(res, 'Booking not found or cannot be cancelled', 404);
    }

    await booking.update({ status: 'cancelled' });

    return successResponse(res, 'Booking cancelled successfully', booking);
  } catch (error) {
    next(error);
  }
};

/**
 * Mark a booking as completed.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const completeBooking = async (req, res, next) => {
  try {
    const booking = await Booking.findOne({
      where: {
        id: req.params.id,
        [Op.or]: [
          { client_id: req.user.id },
          { companion_id: req.user.id }
        ],
        status: { [Op.in]: ['accepted', 'ongoing'] }
      }
    });

    if (!booking) {
      return errorResponse(res, 'Booking not found or cannot be completed', 404);
    }

    await booking.update({ status: 'completed' });

    return successResponse(res, 'Booking completed successfully', booking);
  } catch (error) {
    next(error);
  }
};

/**
 * Submit a review for a completed booking.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const submitReview = async (req, res, next) => {
  try {
    const { rating, comment } = req.body;

    const booking = await Booking.findOne({
      where: {
        id: req.params.id,
        status: 'completed',
        [Op.or]: [
          { client_id: req.user.id },
          { companion_id: req.user.id }
        ]
      }
    });

    if (!booking) {
      return errorResponse(res, 'Booking not found or not completed', 404);
    }

    // Determine reviewer and reviewee
    const reviewerId = req.user.id;
    const revieweeId = booking.client_id === req.user.id
      ? booking.companion_id
      : booking.client_id;

    // Check for duplicate review
    const existingReview = await Review.findOne({
      where: { booking_id: booking.id, reviewer_id: reviewerId }
    });

    if (existingReview) {
      return errorResponse(res, 'You have already reviewed this booking', 409);
    }

    const review = await Review.create({
      booking_id: booking.id,
      reviewer_id: reviewerId,
      reviewee_id: revieweeId,
      rating,
      comment
    });

    // Update companion's avg_rating and total_bookings
    const companionUserId = booking.companion_id;
    const allReviews = await Review.findAll({
      where: { reviewee_id: companionUserId }
    });

    const avgRating = allReviews.reduce((sum, r) => sum + r.rating, 0) / allReviews.length;
    const completedBookings = await Booking.count({
      where: { companion_id: companionUserId, status: 'completed' }
    });

    await CompanionProfile.update(
      {
        avg_rating: Math.round(avgRating * 100) / 100,
        total_bookings: completedBookings
      },
      { where: { user_id: companionUserId } }
    );

    return successResponse(res, 'Review submitted successfully', review, 201);
  } catch (error) {
    next(error);
  }
};
