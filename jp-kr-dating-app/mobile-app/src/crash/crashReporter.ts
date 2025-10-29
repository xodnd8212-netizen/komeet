import * as Sentry from '@sentry/react-native';

const initCrashReporting = () => {
  Sentry.init({
    dsn: 'YOUR_SENTRY_DSN', // Replace with your Sentry DSN
    // Additional configuration options can be added here
  });
};

const captureException = (error: Error) => {
  Sentry.captureException(error);
};

const captureMessage = (message: string) => {
  Sentry.captureMessage(message);
};

export { initCrashReporting, captureException, captureMessage };