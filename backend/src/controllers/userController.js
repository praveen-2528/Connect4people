import { User, CompanionProfile, Photo } from '../models/index.js';
import { uploadToS3, deleteFromS3 } from '../config/s3.js';
import { successResponse, errorResponse } from '../utils/responseHelper.js';

/**
 * Get current authenticated user's profile with companion profile if exists.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const getMe = async (req, res, next) => {
  try {
    const user = await User.findByPk(req.user.id, {
      attributes: { exclude: ['password_hash'] },
      include: [
        { model: CompanionProfile, as: 'companion_profile' },
        { model: Photo, as: 'photos', order: [['sort_order', 'ASC']] }
      ]
    });

    if (!user) {
      return errorResponse(res, 'User not found', 404);
    }

    return successResponse(res, 'Profile retrieved successfully', user);
  } catch (error) {
    next(error);
  }
};

/**
 * Update current user's profile.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const updateMe = async (req, res, next) => {
  try {
    const allowedFields = ['name', 'bio', 'gender', 'dob', 'city', 'phone', 'latitude', 'longitude', 'avatar_url'];
    const updates = {};

    for (const field of allowedFields) {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field];
      }
    }

    await User.update(updates, { where: { id: req.user.id } });

    const updatedUser = await User.findByPk(req.user.id, {
      attributes: { exclude: ['password_hash'] },
      include: [
        { model: CompanionProfile, as: 'companion_profile' },
        { model: Photo, as: 'photos', order: [['sort_order', 'ASC']] }
      ]
    });

    return successResponse(res, 'Profile updated successfully', updatedUser);
  } catch (error) {
    next(error);
  }
};

/**
 * Upload a photo to S3 and save the URL in the photos table.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const uploadPhoto = async (req, res, next) => {
  try {
    let url = req.body?.url;

    if (req.file) {
      url = await uploadToS3(req.file.buffer, req.file.originalname, 'photos');
    }

    if (!url) {
      return errorResponse(res, 'No photo file or photo URL provided', 400);
    }

    // Count existing photos to set sort order
    const photoCount = await Photo.count({ where: { user_id: req.user.id } });
    const isPrimary = photoCount === 0; // First photo is primary

    const photo = await Photo.create({
      user_id: req.user.id,
      url,
      sort_order: photoCount,
      is_primary: isPrimary
    });

    // If first photo, set as avatar
    if (isPrimary) {
      await User.update({ avatar_url: url }, { where: { id: req.user.id } });
    }

    return successResponse(res, 'Photo added successfully', photo, 201);
  } catch (error) {
    next(error);
  }
};

/**
 * Delete a photo from S3 and the database.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const deletePhoto = async (req, res, next) => {
  try {
    const photo = await Photo.findOne({
      where: { id: req.params.id, user_id: req.user.id }
    });

    if (!photo) {
      return errorResponse(res, 'Photo not found', 404);
    }

    // Delete from S3
    try {
      await deleteFromS3(photo.url);
    } catch (s3Error) {
      console.error('S3 deletion error (proceeding with DB deletion):', s3Error.message);
    }

    const wasPrimary = photo.is_primary;
    await photo.destroy();

    // If deleted photo was primary, make the next photo primary
    if (wasPrimary) {
      const nextPhoto = await Photo.findOne({
        where: { user_id: req.user.id },
        order: [['sort_order', 'ASC']]
      });
      if (nextPhoto) {
        await nextPhoto.update({ is_primary: true });
        await User.update({ avatar_url: nextPhoto.url }, { where: { id: req.user.id } });
      } else {
        await User.update({ avatar_url: null }, { where: { id: req.user.id } });
      }
    }

    return successResponse(res, 'Photo deleted successfully');
  } catch (error) {
    next(error);
  }
};
