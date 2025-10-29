import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import { json } from 'body-parser';
import routes from './routes/index';
import { errorHandler } from './middlewares/errorHandler';
import { connectToDatabase } from './utils/database';
import { logger } from './utils/logger';

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(json());
app.use(rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100 // limit each IP to 100 requests per windowMs
}));

// Connect to Database
connectToDatabase();

// Routes
app.use('/api', routes);

// Error Handling Middleware
app.use(errorHandler);

// Start Server
app.listen(PORT, () => {
    logger.info(`Server is running on http://localhost:${PORT}`);
});