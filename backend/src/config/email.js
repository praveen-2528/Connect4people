import nodemailer from 'nodemailer';

/**
 * Extract SMTP credentials from all possible environment variable aliases.
 * Automatically cleans whitespace from Google App Passwords (e.g. "abcd efgh ijkl mnop" -> "abcdefghijklmnop").
 */
export const getSmtpCredentials = () => {
  const user = process.env.SMTP_USER ||
               process.env.SMTP_USERNAME ||
               process.env.EMAIL_USER ||
               process.env.EMAIL_USERNAME ||
               process.env.GMAIL_USER ||
               process.env.GMAIL_USERNAME ||
               process.env.GMAIL_EMAIL ||
               process.env.GMAIL ||
               process.env.EMAIL ||
               process.env.MAIL_USER ||
               process.env.USER_EMAIL;

  const rawPass = process.env.SMTP_PASS ||
                  process.env.SMTP_PASSWORD ||
                  process.env.EMAIL_PASS ||
                  process.env.EMAIL_PASSWORD ||
                  process.env.GMAIL_PASS ||
                  process.env.GMAIL_PASSWORD ||
                  process.env.GMAIL_APP_PASSWORD ||
                  process.env.APP_PASSWORD ||
                  process.env.APP_PASS ||
                  process.env.MAIL_PASS;

  const pass = rawPass ? rawPass.trim().replace(/\s+/g, '') : null;
  return { user: user ? user.trim() : null, pass };
};

/**
 * Create Nodemailer transporter for Gmail.
 */
export const createTransporter = () => {
  const { user, pass } = getSmtpCredentials();
  if (!user || !pass) return null;

  return nodemailer.createTransport({
    service: 'gmail',
    auth: { user, pass },
    connectionTimeout: 8000,
    greetingTimeout: 8000,
    socketTimeout: 8000
  });
};

/**
 * Send email via Resend HTTPS REST API (Port 443).
 * Always unblocked on Render Free Tier, AWS, and serverless hosts.
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
 * Tries Resend HTTPS API (Port 443) first, then Gmail SMTP.
 * 
 * @param {string} email - Recipient email address
 * @param {string} otp - The OTP code to send
 * @param {string} purpose - Purpose of the OTP ('login' | 'signup')
 * @returns {Promise<{ success: boolean, provider: string, error?: string }>}
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

  // 1. Try Resend HTTP API (HTTPS port 443 - works everywhere)
  if (process.env.RESEND_API_KEY) {
    try {
      await sendViaResend(email, subject, html);
      console.log(`[Email] OTP sent to ${email} via Resend HTTPS API.`);
      return { success: true, provider: 'resend' };
    } catch (err) {
      console.warn(`[Email] Resend API failed: ${err.message}`);
    }
  }

  // 2. Try Nodemailer Gmail SMTP
  const { user: smtpUser, pass: smtpPass } = getSmtpCredentials();
  if (smtpUser && smtpPass && smtpPass !== 'your_gmail_app_password') {
    try {
      const transporter = createTransporter();
      await transporter.sendMail({
        from: `"Connect4People" <${smtpUser}>`,
        to: email,
        subject,
        html
      });
      console.log(`[Email] ✅ Real OTP email sent successfully to ${email} via Gmail SMTP.`);
      return { success: true, provider: 'gmail_smtp' };
    } catch (smtpErr) {
      console.warn(`[Email] Gmail SMTP error (${smtpErr.message}).`);
      return { success: false, provider: 'gmail_smtp', error: smtpErr.message };
    }
  }

  console.log(`[Email] No active email credentials found in environment variables.`);
  return { success: false, provider: 'none', error: 'No SMTP credentials configured on server' };
};

export default { sendOtpEmail, getSmtpCredentials, createTransporter };
