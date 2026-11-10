/**
 * Default platform commission percentage.
 */
const DEFAULT_COMMISSION = 20;

/**
 * Calculate the platform fee and companion payout for a booking amount.
 * @param {number} totalAmount - The total booking amount
 * @param {number} [commissionPercent=20] - Commission percentage (default 20%)
 * @returns {{ amount: number, platformFee: number, companionPayout: number }}
 */
export const calculateFees = (totalAmount, commissionPercent = DEFAULT_COMMISSION) => {
  const amount = parseFloat(totalAmount);
  const platformFee = Math.round((amount * commissionPercent) / 100 * 100) / 100;
  const companionPayout = Math.round((amount - platformFee) * 100) / 100;

  return {
    amount,
    platformFee,
    companionPayout
  };
};

export default calculateFees;
