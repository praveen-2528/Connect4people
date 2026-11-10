import { DataTypes } from 'sequelize';

/**
 * Payment model definition.
 * @param {import('sequelize').Sequelize} sequelize
 * @returns {import('sequelize').Model}
 */
const PaymentModel = (sequelize) => {
  const Payment = sequelize.define('Payment', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    user_id: {
      type: DataTypes.UUID,
      allowNull: false,
      references: { model: 'users', key: 'id' }
    },
    booking_id: {
      type: DataTypes.UUID,
      allowNull: true,
      references: { model: 'bookings', key: 'id' }
    },
    payment_type: {
      type: DataTypes.ENUM('registration', 'booking', 'commission'),
      allowNull: false
    },
    amount: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false
    },
    status: {
      type: DataTypes.ENUM('pending', 'claimed', 'verified', 'rejected'),
      defaultValue: 'pending'
    },
    method: {
      type: DataTypes.STRING(50),
      allowNull: true
    },
    reference_note: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    claimed_at: {
      type: DataTypes.DATE,
      allowNull: true
    },
    verified_at: {
      type: DataTypes.DATE,
      allowNull: true
    }
  }, {
    tableName: 'payments',
    underscored: true,
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false
  });

  return Payment;
};

export default PaymentModel;
