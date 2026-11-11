import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';

// Load .env.local first if it exists, then fallback to .env
if (fs.existsSync(path.resolve(process.cwd(), '.env.local'))) {
  dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });
}
dotenv.config();

import { sequelize, AppConfig } from '../models/index.js';

/**
 * Cleanly drops and recreates all database tables.
 * Only seeds standard configuration defaults (fees, platform commission).
 * Does not insert any dummy users or fake companions.
 */
const resetDatabase = async () => {
  try {
    console.log('[DB Reset] Connecting to PostgreSQL at', process.env.DB_HOST, '...');
    await sequelize.authenticate();
    console.log('[DB Reset] Database connection established.');

    console.log('[DB Reset] Wiping existing tables and recreating schema (force: true)...');
    await sequelize.sync({ force: true });
    console.log('[DB Reset] All tables cleanly recreated.');

    // Seed only required baseline platform configurations
    const baselineConfigs = [
      { key: 'registration_fee', value: process.env.REGISTRATION_FEE_INR || '299' },
      { key: 'commission_percentage', value: process.env.PLATFORM_COMMISSION_PERCENT || '20' },
      { key: 'upi_id', value: 'connect4people@upi' },
      { key: 'upi_qr_url', value: '' },
      { key: 'platform_name', value: 'Connect4People' }
    ];

    for (const item of baselineConfigs) {
      await AppConfig.upsert(item);
    }
    console.log('[DB Reset] Baseline application config initialized.');

    await sequelize.close();
    console.log('[DB Reset] Database reset complete! Ready for clean usage.');
    process.exit(0);
  } catch (err) {
    console.error('[DB Reset] Error during database reset:', err.message);
    process.exit(1);
  }
};

resetDatabase();
