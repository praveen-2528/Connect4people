import { DataTypes } from 'sequelize';

/**
 * AppConfig model definition. Key-value store for application configuration.
 * @param {import('sequelize').Sequelize} sequelize
 * @returns {import('sequelize').Model}
 */
const AppConfigModel = (sequelize) => {
  const AppConfig = sequelize.define('AppConfig', {
    key: {
      type: DataTypes.STRING(100),
      primaryKey: true,
      allowNull: false
    },
    value: {
      type: DataTypes.TEXT,
      allowNull: true
    }
  }, {
    tableName: 'app_config',
    underscored: true,
    timestamps: true,
    createdAt: false,
    updatedAt: 'updated_at'
  });

  return AppConfig;
};

export default AppConfigModel;
