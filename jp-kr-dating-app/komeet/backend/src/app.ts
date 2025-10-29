import express from 'express';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { json } from 'body-parser';
import { authRoutes } from './routes/auth.routes';
import { userRoutes } from './routes/users.routes';
import { errorMiddleware } from './middlewares/error.middleware';

const app = express();

// Middleware
app.use(helmet());
app.use(json());
app.use(rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
}));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);

// Error handling middleware
app.use(errorMiddleware);

export default app;