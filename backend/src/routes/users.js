import { Router } from 'express';
import { body } from 'express-validator';
import { getMe, updateMe, uploadPhoto, deletePhoto } from '../controllers/userController.js';
import { createCompanionProfile, updateCompanionProfile } from '../controllers/companionController.js';
import { validate } from '../middleware/validate.js';
import { authenticate } from '../middleware/auth.js';
import upload from '../middleware/upload.js';

const router = Router();

// All user routes require authentication
router.use(authenticate);

/**
 * @route GET /api/users/me
 * @desc Get current user profile with companion_profile
 */
router.get('/me', getMe);

/**
 * @route PUT /api/users/me
 * @desc Update current user profile
 */
router.put(
  '/me',
  [
    body('name').optional().isString().trim().isLength({ max: 100 }).withMessage('Name must be at most 100 characters'),
    body('bio').optional().isString().withMessage('Bio must be a string'),
    body('gender').optional().isString().withMessage('Gender must be a string'),
    body('dob').optional().isISO8601().withMessage('DOB must be a valid date'),
    body('city').optional().isString().trim().withMessage('City must be a string'),
    body('phone').optional().isString().trim().withMessage('Phone must be a string'),
    body('latitude').optional().isDecimal().withMessage('Latitude must be a decimal'),
    body('longitude').optional().isDecimal().withMessage('Longitude must be a decimal')
  ],
  validate,
  updateMe
);

/**
 * @route POST /api/users/me/photos
 * @desc Upload a photo or add photo URL
 */
router.post(
  '/me/photos',
  (req, res, next) => {
    if (req.is('multipart/form-data')) {
      return upload.single('photo')(req, res, next);
    }
    next();
  },
  uploadPhoto
);

/**
 * @route DELETE /api/users/me/photos/:id
 * @desc Delete a photo from S3 and DB
 */
router.delete('/me/photos/:id', deletePhoto);

/**
 * @route POST /api/users/me/companion
 * @desc Create companion profile
 */
router.post(
  '/me/companion',
  [
    body('hourly_rate').optional().isDecimal().withMessage('Hourly rate must be a number'),
    body('event_rate').optional().isDecimal().withMessage('Event rate must be a number'),
    body('languages').optional().isArray().withMessage('Languages must be an array'),
    body('interests').optional().isArray().withMessage('Interests must be an array'),
    body('available_days').optional().isArray().withMessage('Available days must be an array'),
    body('tagline').optional().isString().trim().isLength({ max: 255 }).withMessage('Tagline max 255 characters')
  ],
  validate,
  createCompanionProfile
);

/**
 * @route PUT /api/users/me/companion
 * @desc Update companion profile
 */
router.put(
  '/me/companion',
  [
    body('hourly_rate').optional().isDecimal().withMessage('Hourly rate must be a number'),
    body('event_rate').optional().isDecimal().withMessage('Event rate must be a number'),
    body('languages').optional().isArray().withMessage('Languages must be an array'),
    body('interests').optional().isArray().withMessage('Interests must be an array'),
    body('available_days').optional().isArray().withMessage('Available days must be an array'),
    body('tagline').optional().isString().trim().isLength({ max: 255 }).withMessage('Tagline max 255 characters'),
    body('is_listed').optional().isBoolean().withMessage('is_listed must be a boolean')
  ],
  validate,
  updateCompanionProfile
);

export default router;
