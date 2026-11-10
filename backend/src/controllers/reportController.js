import { Report } from '../models/index.js';
import { successResponse, errorResponse } from '../utils/responseHelper.js';

/**
 * Create a new report against a user.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const createReport = async (req, res, next) => {
  try {
    const { reported_user_id, booking_id, reason, description } = req.body;

    if (req.user.id === reported_user_id) {
      return errorResponse(res, 'You cannot report yourself', 400);
    }

    const report = await Report.create({
      reporter_id: req.user.id,
      reported_user_id,
      booking_id: booking_id || null,
      reason,
      description: description || null,
      status: 'pending'
    });

    return successResponse(res, 'Report submitted successfully', report, 201);
  } catch (error) {
    next(error);
  }
};
