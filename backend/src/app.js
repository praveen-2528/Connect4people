import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';

dotenv.config();

// Route imports
import authRoutes from './routes/auth.js';
import userRoutes from './routes/users.js';
import companionRoutes from './routes/companions.js';
import bookingRoutes from './routes/bookings.js';
import conversationRoutes from './routes/conversations.js';
import paymentRoutes from './routes/payments.js';
import reportRoutes from './routes/reports.js';
import adminRoutes from './routes/admin.js';

import path from 'path';
import { fileURLToPath } from 'url';

// Middleware imports
import { errorHandler } from './middleware/errorHandler.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();

// Security and utility middleware
app.use(helmet({
  contentSecurityPolicy: false,
  crossOriginEmbedderPolicy: false
}));
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Serve Admin Portal web app
app.use('/admin', express.static(path.join(__dirname, '../public/admin')));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/companions', companionRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/conversations', conversationRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/admin', adminRoutes);

// 404 Handler for undefined routes
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Route not found: ${req.method} ${req.originalUrl}`
  });
});

// Global Error Handler
app.use(errorHandler);

export default app;
