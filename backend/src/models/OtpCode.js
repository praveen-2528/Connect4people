import { DataTypes } from 'sequelize';

/**
 * OtpCode model definition.
 * @param {import('sequelize').Sequelize} sequelize
 * @returns {import('sequelize').Model}
 */
const OtpCodeModel = (sequelize) => {
  const OtpCode = sequelize.define('OtpCode', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    email: {
      type: DataTypes.STRING(255),
      allowNull: false,
      validate: { isEmail: true }
    },
    code: {
      type: DataTypes.STRING(6),
      allowNull: false
    },
    purpose: {
      type: DataTypes.ENUM('login', 'signup'),
      allowNull: false
    },
    expires_at: {
      type: DataTypes.DATE,
      allowNull: false
    },
    is_used: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    }
  }, {
    tableName: 'otp_codes',
    underscored: true,
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false
  });

  return OtpCode;
};

export default OtpCodeModel;
