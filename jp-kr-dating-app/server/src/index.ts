import express from 'express';
import { json } from 'body-parser';
import helmet from 'helmet';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import { createConnection } from 'typeorm';
import routes from './routes';
import { errorHandler } from './middlewares/errorHandler';
import { connectToDatabase } from './utils/database';
import { initializePushNotifications } from './integrations/push';
import { initializeCrashReporting } from './integrations/crashReporting';

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

// Routes
app.use('/api', routes);

// Error handling middleware
app.use(errorHandler);

// Database connection
connectToDatabase()
    .then(() => {
        console.log('Database connected successfully');
        // Initialize push notifications and crash reporting
        initializePushNotifications();
        initializeCrashReporting();
        
        // Start the server
        app.listen(PORT, () => {
            console.log(`Server is running on http://localhost:${PORT}`);
        });
    })
    .catch(err => {
        console.error('Database connection failed:', err);
        process.exit(1);
    });