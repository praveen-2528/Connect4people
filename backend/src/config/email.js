import nodemailer from 'nodemailer';

/**
 * Create and configure the Nodemailer transporter for Gmail SMTP.
 * @returns {import('nodemailer').Transporter} Configured mail transporter
 */
const createTransporter = () => {
  const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: parseInt(process.env.SMTP_PORT, 10) || 587,
    secure: false,
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS
    }
  });

  return transporter;
};

const transporter = createTransporter();

/**
 * Send an OTP email to the specified address.
 * @param {string} email - Recipient email address
 * @param {string} otp - The OTP code to send
 * @param {string} purpose - Purpose of the OTP ('login' | 'signup')
 * @returns {Promise<void>}
 */
export const sendOtpEmail = async (email, otp, purpose) => {
  const subject = purpose === 'signup'
    ? 'Connect4People — Your Signup OTP'
    : 'Connect4People — Your Login OTP';

  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 24px;">
      <h2 style="color: #6C63FF;">Connect4People</h2>
      <p>Your OTP for <strong>${purpose}</strong> is:</p>
      <div style="font-size: 32px; font-weight: bold; color: #6C63FF; letter-spacing: 6px; margin: 24px 0;">${otp}</div>
      <p style="color: #888;">This code is valid for 10 minutes. Do not share it with anyone.</p>
    </div>
  `;

  await transporter.sendMail({
    from: `"Connect4People" <${process.env.SMTP_USER}>`,
    to: email,
    subject,
    html
  });
};

export default transporter;
