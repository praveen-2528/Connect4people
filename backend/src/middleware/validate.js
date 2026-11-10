import { validationResult } from 'express-validator';
import { errorResponse } from '../utils/responseHelper.js';

/**
 * Middleware to handle express-validator validation errors.
 * Returns 422 with array of validation error messages if validation fails.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const extractedErrors = errors.array().map((err) => ({
      field: err.path,
      message: err.msg
    }));
    return errorResponse(res, 'Validation failed', 422, extractedErrors);
  }
  next();
};

export default validate;
