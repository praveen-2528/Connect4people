import nodemailer from 'nodemailer';

/**
 * Create and configure the Nodemailer transporter for Gmail SMTP with strict connection timeouts.
 * Render Free Tier blocks outbound ports 25, 465, and 587, so timeouts ensure the app never hangs.
 * @returns {import('nodemailer').Transporter} Configured mail transporter
 */
const createTransporter = () => {
  const isPort465 = parseInt(process.env.SMTP_PORT, 10) === 465;
  const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: parseInt(process.env.SMTP_PORT, 10) || 587,
    secure: isPort465,
    connectionTimeout: 4000, // 4s timeout to avoid hanging when cloud firewall blocks SMTP
    greetingTimeout: 4000,
    socketTimeout: 5000,
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS
    }
  });

  return transporter;
};

/**
 * Send email via Resend HTTPS REST API (Port 443).
 * 100% compatible with Render Free Tier, AWS, and serverless environments.
 * @param {string} email
 * @param {string} subject
 * @param {string} html
 */
const sendViaResend = async (email, subject, html) => {
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey) return null;

  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      from: process.env.EMAIL_FROM || 'Connect4People <onboarding@resend.dev>',
      to: [email],
      subject,
      html
    })
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`Resend API Error: ${errText}`);
  }

  return await res.json();
};

/**
 * Send an OTP email to the specified address.
 * Automatically attempts Resend HTTPS API first (unblocked on Render Free Tier),
 * then falls back to SMTP with strict timeouts.
 * 
 * @param {string} email - Recipient email address
 * @param {string} otp - The OTP code to send
 * @param {string} purpose - Purpose of the OTP ('login' | 'signup')
 * @returns {Promise<{ success: boolean, provider: string }>}
 */
export const sendOtpEmail = async (email, otp, purpose) => {
  const subject = purpose === 'signup'
    ? 'Connect4People — Your Signup OTP'
    : 'Connect4People — Your Login OTP';

  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 24px; border: 1px solid #e2e8f0; border-radius: 12px; background-color: #ffffff;">
      <h2 style="color: #6C63FF; margin-bottom: 8px;">Connect4People</h2>
      <p style="font-size: 15px; color: #4a5568;">Your verification code for <strong>${purpose}</strong> is:</p>
      <div style="font-size: 36px; font-weight: bold; color: #6C63FF; letter-spacing: 8px; margin: 24px 0; padding: 16px; background-color: #f7fafc; text-align: center; border-radius: 8px;">${otp}</div>
      <p style="color: #718096; font-size: 13px;">This code expires in 10 minutes. For your security, do not share this OTP with anyone.</p>
    </div>
  `;

  // 1. Try Resend HTTP API (HTTPS port 443 - works on Render Free Tier)
  if (process.env.RESEND_API_KEY) {
    try {
      await sendViaResend(email, subject, html);
      console.log(`[Email] OTP sent to ${email} via Resend HTTPS API.`);
      return { success: true, provider: 'resend' };
    } catch (err) {
      console.warn(`[Email] Resend API failed: ${err.message}`);
    }
  }

  // 2. Try Nodemailer SMTP (e.g. Gmail App Password)
  if (process.env.SMTP_USER && process.env.SMTP_PASS && process.env.SMTP_PASS !== 'your_gmail_app_password') {
    try {
      const transporter = createTransporter();
      await transporter.sendMail({
        from: `"Connect4People" <${process.env.SMTP_USER}>`,
        to: email,
        subject,
        html
      });
      console.log(`[Email] OTP sent to ${email} via SMTP.`);
      return { success: true, provider: 'smtp' };
    } catch (smtpErr) {
      console.warn(`[Email] SMTP failed (${smtpErr.message}). (Note: Render Free Tier blocks outbound SMTP ports 25, 465, 587. Use RESEND_API_KEY or upgrade Render instance).`);
      throw smtpErr;
    }
  }

  console.log(`[Email] No active email provider configured (Set RESEND_API_KEY or SMTP_USER/SMTP_PASS).`);
  return { success: false, provider: 'none' };
};

export default { sendOtpEmail };
