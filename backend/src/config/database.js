import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';

// Load .env.local first if it exists (written by neon deploy / neon env pull), then fallback to .env
if (fs.existsSync(path.resolve(process.cwd(), '.env.local'))) {
  dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });
}
dotenv.config();

import { Sequelize } from 'sequelize';

const isProduction = process.env.NODE_ENV === 'production';
const rawDbUrl = (process.env.DATABASE_URL || '').trim();
const isUriValid = rawDbUrl.startsWith('postgres://') || rawDbUrl.startsWith('postgresql://');
const useSSL = process.env.DB_SSL === 'true' || isUriValid;

let sequelize;

function createDiscreteSequelize() {
  return new Sequelize(
    process.env.DB_NAME || 'connect4people',
    process.env.DB_USER || 'postgres',
    process.env.DB_PASSWORD || 'postgres',
    {
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT, 10) || 5432,
      dialect: 'postgres',
      logging: !isProduction ? console.log : false,
      dialectOptions: useSSL
        ? {
            ssl: {
              require: true,
              rejectUnauthorized: false
            }
          }
        : {},
      pool: {
        max: 10,
        min: 0,
        acquire: 30000,
        idle: 10000
      },
      define: {
        underscored: true,
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at'
      }
    }
  );
}

if (isUriValid) {
  try {
    // Parse using WHATWG URL standard to bypass legacy url.parse() issues in Node.js
    const parsed = new URL(rawDbUrl);
    const dbName = parsed.pathname.replace(/^\//, '') || 'neondb';
    const dbUser = decodeURIComponent(parsed.username || 'postgres');
    const dbPass = decodeURIComponent(parsed.password || '');
    const dbHost = parsed.hostname;
    const dbPort = parseInt(parsed.port, 10) || 5432;

    sequelize = new Sequelize(dbName, dbUser, dbPass, {
      host: dbHost,
      port: dbPort,
      dialect: 'postgres',
      logging: !isProduction ? console.log : false,
      dialectOptions: useSSL
        ? {
            ssl: {
              require: true,
              rejectUnauthorized: false
            }
          }
        : {},
      pool: {
        max: 10,
        min: 0,
        acquire: 30000,
        idle: 10000
      },
      define: {
        underscored: true,
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at'
      }
    });
  } catch (parseErr) {
    console.error('[Database] Failed to parse DATABASE_URL with WHATWG URL:', parseErr.message);
    sequelize = createDiscreteSequelize();
  }
} else {
  if (rawDbUrl) {
    console.warn('[Database] DATABASE_URL provided but does not start with postgres:// or postgresql://. Using discrete configuration.');
  }
  sequelize = createDiscreteSequelize();
}

export default sequelize;

// CommonJS export for sequelize-cli migrations
const development = {
  username: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'password',
  database: process.env.DB_NAME || 'connect4people',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT, 10) || 5432,
  dialect: 'postgres'
};

const production = {
  username: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT, 10) || 5432,
  dialect: 'postgres',
  logging: false
};

export { development, production };
