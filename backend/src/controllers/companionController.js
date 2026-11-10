import { Op } from 'sequelize';
import { User, CompanionProfile, Photo, Review } from '../models/index.js';
import { successResponse, errorResponse } from '../utils/responseHelper.js';

/**
 * Create a companion profile for the current user.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const createCompanionProfile = async (req, res, next) => {
  try {
    // Check if already a companion
    const existing = await CompanionProfile.findOne({ where: { user_id: req.user.id } });
    if (existing) {
      return errorResponse(res, 'Companion profile already exists', 409);
    }

    const {
      hourly_rate, event_rate, languages, interests,
      available_days, available_hours_start, available_hours_end, tagline
    } = req.body;

    const profile = await CompanionProfile.create({
      user_id: req.user.id,
      hourly_rate,
      event_rate,
      languages: languages || [],
      interests: interests || [],
      available_days: available_days || [],
      available_hours_start,
      available_hours_end,
      tagline
    });

    // Set user as companion
    await User.update({ is_companion: true }, { where: { id: req.user.id } });

    return successResponse(res, 'Companion profile created successfully', profile, 201);
  } catch (error) {
    next(error);
  }
};

/**
 * Update the current user's companion profile.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const updateCompanionProfile = async (req, res, next) => {
  try {
    const profile = await CompanionProfile.findOne({ where: { user_id: req.user.id } });
    if (!profile) {
      return errorResponse(res, 'Companion profile not found. Create one first.', 404);
    }

    const allowedFields = [
      'hourly_rate', 'event_rate', 'languages', 'interests',
      'available_days', 'available_hours_start', 'available_hours_end',
      'tagline', 'is_listed'
    ];

    const updates = {};
    for (const field of allowedFields) {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field];
      }
    }

    await profile.update(updates);

    return successResponse(res, 'Companion profile updated successfully', profile);
  } catch (error) {
    next(error);
  }
};

/**
 * List companions with filters, pagination, and sorting.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const listCompanions = async (req, res, next) => {
  try {
    const {
      city, gender, interests, min_price, max_price, min_rating,
      sort = 'newest', page = 1, limit = 20
    } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limit);
    const userWhere = { is_companion: true, is_active: true };
    const companionWhere = { is_listed: true };

    // User-level filters
    if (city) userWhere.city = { [Op.iLike]: `%${city}%` };
    if (gender) userWhere.gender = gender;

    // Companion profile filters
    if (min_price) companionWhere.hourly_rate = { ...companionWhere.hourly_rate, [Op.gte]: parseFloat(min_price) };
    if (max_price) companionWhere.hourly_rate = { ...companionWhere.hourly_rate, [Op.lte]: parseFloat(max_price) };
    if (min_rating) companionWhere.avg_rating = { [Op.gte]: parseFloat(min_rating) };
    if (interests) {
      const interestList = Array.isArray(interests) ? interests : interests.split(',');
      companionWhere.interests = { [Op.overlap]: interestList };
    }

    // Sorting
    let order;
    switch (sort) {
      case 'rating':
        order = [[{ model: CompanionProfile, as: 'companion_profile' }, 'avg_rating', 'DESC']];
        break;
      case 'price_low':
        order = [[{ model: CompanionProfile, as: 'companion_profile' }, 'hourly_rate', 'ASC']];
        break;
      case 'price_high':
        order = [[{ model: CompanionProfile, as: 'companion_profile' }, 'hourly_rate', 'DESC']];
        break;
      case 'newest':
      default:
        order = [['created_at', 'DESC']];
        break;
    }

    const { count, rows: companions } = await User.findAndCountAll({
      where: userWhere,
      attributes: { exclude: ['password_hash'] },
      include: [
        {
          model: CompanionProfile,
          as: 'companion_profile',
          where: companionWhere,
          required: true
        },
        {
          model: Photo,
          as: 'photos',
          attributes: ['id', 'url', 'sort_order', 'is_primary'],
          separate: true,
          order: [['sort_order', 'ASC']]
        }
      ],
      order,
      limit: parseInt(limit),
      offset,
      distinct: true
    });

    return successResponse(res, 'Companions retrieved successfully', {
      companions,
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
 * Get companion detail by user ID with photos and reviews.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const getCompanionDetail = async (req, res, next) => {
  try {
    const companion = await User.findOne({
      where: { id: req.params.id, is_companion: true },
      attributes: { exclude: ['password_hash'] },
      include: [
        { model: CompanionProfile, as: 'companion_profile' },
        {
          model: Photo,
          as: 'photos',
          attributes: ['id', 'url', 'sort_order', 'is_primary'],
          order: [['sort_order', 'ASC']]
        },
        {
          model: Review,
          as: 'reviews_received',
          limit: 5,
          order: [['created_at', 'DESC']],
          include: [
            {
              model: User,
              as: 'reviewer',
              attributes: ['id', 'name', 'avatar_url']
            }
          ]
        }
      ]
    });

    if (!companion) {
      return errorResponse(res, 'Companion not found', 404);
    }

    return successResponse(res, 'Companion details retrieved successfully', companion);
  } catch (error) {
    next(error);
  }
};

/**
 * Get paginated reviews for a companion.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const getCompanionReviews = async (req, res, next) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const { count, rows: reviews } = await Review.findAndCountAll({
      where: { reviewee_id: req.params.id },
      include: [
        {
          model: User,
          as: 'reviewer',
          attributes: ['id', 'name', 'avatar_url']
        }
      ],
      order: [['created_at', 'DESC']],
      limit: parseInt(limit),
      offset
    });

    return successResponse(res, 'Reviews retrieved successfully', {
      reviews,
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
