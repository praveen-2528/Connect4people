import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';

// Load .env.local first if it exists, then fallback to .env
if (fs.existsSync(path.resolve(process.cwd(), '.env.local'))) {
  dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });
}
dotenv.config();

import { sequelize, AppConfig } from '../models/index.js';

const syncDatabase = async () => {
  try {
    console.log('[DB Sync] Connecting to PostgreSQL at', process.env.DB_HOST, '...');
    await sequelize.authenticate();
    console.log('[DB Sync] Database connection established.');

    console.log('[DB Sync] Syncing models (force: false, alter: true)...');
    await sequelize.sync({ alter: true });
    console.log('[DB Sync] All tables created/synchronized successfully!');

    // Seed defaults
    const defaults = [
      { key: 'registration_fee', value: '299' },
      { key: 'commission_percentage', value: '20' },
      { key: 'upi_id', value: 'connect4people@upi' },
      { key: 'upi_qr_url', value: '' },
      { key: 'platform_name', value: 'Connect4People' }
    ];

    for (const item of defaults) {
      await AppConfig.findOrCreate({
        where: { key: item.key },
        defaults: item
      });
    }
    console.log('[DB Sync] Default config entries seeded.');

    await sequelize.close();
    console.log('[DB Sync] Completed.');
    process.exit(0);
  } catch (err) {
    console.error('[DB Sync] Error syncing database:', err);
    process.exit(1);
  }
};

syncDatabase();
