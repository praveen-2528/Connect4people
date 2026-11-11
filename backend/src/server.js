import http from 'http';
import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';

// Load .env.local first if it exists, then fallback to .env
if (fs.existsSync(path.resolve(process.cwd(), '.env.local'))) {
  dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });
}
dotenv.config();

import app from './app.js';
import { setupSocket } from './config/socket.js';
import { sequelize, AppConfig } from './models/index.js';

const PORT = parseInt(process.env.PORT, 10) || 5000;

const server = http.createServer(app);

// Attach Socket.io
export const io = setupSocket(server);

/**
 * Seed initial config entries if not already present
 */
const seedInitialConfig = async () => {
  try {
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
    console.log('[Server] Default app_config verified.');
  } catch (error) {
    console.warn('[Server] Note: AppConfig seed skipped or deferred:', error.message);
  }
};

/**
 * Initialize and start the application server
 */
const startServer = async () => {
  try {
    // Authenticate database connection
    console.log('[Database] Connecting to PostgreSQL...');
    await sequelize.authenticate();
    console.log('[Database] PostgreSQL connected successfully.');

    // Sync database tables only when explicitly requested (schema is managed via db:sync)
    if (process.env.DB_AUTO_SYNC === 'true') {
      console.log('[Database] Synchronizing schema...');
      await sequelize.sync({ alter: true });
      console.log('[Database] Schema synchronized.');
    }

    // Seed default configurations
    await seedInitialConfig();

    // Start listening
    server.listen(PORT, () => {
      console.log(`===============================================`);
      console.log(`🚀 Connect4People API Server running on port ${PORT}`);
      console.log(`🌐 Health check: http://localhost:${PORT}/health`);
      console.log(`⚙️  Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`===============================================`);
    });
  } catch (error) {
    console.error('[Server] Failed to connect to database on startup:', error.message);
    console.log('[Server] Starting HTTP server anyway so endpoints and health check respond...');
    
    // Allow server to still boot even if DB is pending configuration
    server.listen(PORT, () => {
      console.log(`🚀 Connect4People API Server running on port ${PORT} (Database offline or pending config)`);
    });
  }
};

startServer();

// Handle termination signals cleanly
process.on('SIGTERM', async () => {
  console.log('[Server] SIGTERM received. Closing server gracefully...');
  server.close(async () => {
    await sequelize.close();
    process.exit(0);
  });
});

process.on('SIGINT', async () => {
  console.log('[Server] SIGINT received. Closing server gracefully...');
  server.close(async () => {
    await sequelize.close();
    process.exit(0);
  });
});
