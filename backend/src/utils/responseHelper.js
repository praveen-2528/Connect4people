/**
 * Send a standardized success response.
 * @param {import('express').Response} res - Express response object
 * @param {string} message - Response message
 * @param {*} [data=null] - Response data payload
 * @param {number} [statusCode=200] - HTTP status code
 * @returns {import('express').Response}
 */
export const successResponse = (res, message, data = null, statusCode = 200) => {
  return res.status(statusCode).json({
    success: true,
    message,
    data
  });
};

/**
 * Send a standardized error response.
 * @param {import('express').Response} res - Express response object
 * @param {string} message - Error message
 * @param {number} [statusCode=500] - HTTP status code
 * @param {*} [errors=null] - Additional error details
 * @returns {import('express').Response}
 */
export const errorResponse = (res, message, statusCode = 500, errors = null) => {
  const body = {
    success: false,
    message
  };
  if (errors) body.errors = errors;
  return res.status(statusCode).json(body);
};

export default { successResponse, errorResponse };
