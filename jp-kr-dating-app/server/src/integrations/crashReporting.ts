import { init as initSentry, captureException } from '@sentry/node';

const SENTRY_DSN = process.env.SENTRY_DSN;

export const initCrashReporting = () => {
    if (!SENTRY_DSN) {
        console.warn('SENTRY_DSN is not defined. Crash reporting is disabled.');
        return;
    }

    initSentry({
        dsn: SENTRY_DSN,
        tracesSampleRate: 1.0, // Adjust this value in production
    });
};

export const reportError = (error: Error) => {
    captureException(error);
};