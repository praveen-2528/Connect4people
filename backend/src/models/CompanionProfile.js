import { DataTypes } from 'sequelize';

/**
 * CompanionProfile model definition.
 * @param {import('sequelize').Sequelize} sequelize
 * @returns {import('sequelize').Model}
 */
const CompanionProfileModel = (sequelize) => {
  const CompanionProfile = sequelize.define('CompanionProfile', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    user_id: {
      type: DataTypes.UUID,
      allowNull: false,
      unique: true,
      references: { model: 'users', key: 'id' }
    },
    hourly_rate: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: true
    },
    event_rate: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: true
    },
    languages: {
      type: DataTypes.ARRAY(DataTypes.STRING),
      defaultValue: []
    },
    interests: {
      type: DataTypes.ARRAY(DataTypes.STRING),
      defaultValue: []
    },
    available_days: {
      type: DataTypes.ARRAY(DataTypes.STRING),
      defaultValue: []
    },
    available_hours_start: {
      type: DataTypes.TIME,
      allowNull: true
    },
    available_hours_end: {
      type: DataTypes.TIME,
      allowNull: true
    },
    tagline: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    avg_rating: {
      type: DataTypes.DECIMAL(3, 2),
      defaultValue: 0
    },
    total_bookings: {
      type: DataTypes.INTEGER,
      defaultValue: 0
    },
    is_listed: {
      type: DataTypes.BOOLEAN,
      defaultValue: true
    }
  }, {
    tableName: 'companion_profiles',
    underscored: true,
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at'
  });

  return CompanionProfile;
};

export default CompanionProfileModel;
