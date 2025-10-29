# Komeet Dating App

Komeet is a dating application designed to connect users in a fun and engaging way. The app features a modern interface similar to popular dating apps like Wippy, Glam, and Tinder, providing users with an intuitive experience for finding matches.

## Project Structure

The project is divided into two main parts: the mobile application and the backend server.

### Mobile Application

The mobile application is built using Flutter and follows a clean architecture. Below are the key components:

- **lib/**: Contains the main application code.
  - **main.dart**: Entry point of the Flutter application.
  - **app.dart**: Main application widget with global providers.
  - **theme/**: Contains theme definitions.
  - **routes/**: Manages app routing.
  - **features/**: Contains feature-specific code (e.g., profile, match, settings).
  - **models/**: Defines data models used in the app.
  - **state/**: Contains state management logic.
  - **services/**: Handles API calls, authentication, and file uploads.
  - **integrations/**: Integrates third-party services like Sentry and push notifications.
  - **utils/**: Contains utility functions.
  - **widgets/**: Reusable UI components.

### Backend Server

The backend server is built using TypeScript and Express. It provides the necessary APIs for the mobile application. Key components include:

- **src/**: Contains the main server code.
  - **server.ts**: Entry point for the backend server.
  - **app.ts**: Initializes middleware and routes.
  - **routes/**: Defines API routes for authentication and user management.
  - **controllers/**: Contains business logic for handling requests.
  - **services/**: Manages core functionalities like authentication and file uploads.
  - **middlewares/**: Implements middleware for authentication, error handling, and security.
  - **schemas/**: Defines validation schemas for incoming requests.
  - **utils/**: Contains utility functions for JWT handling.

### Database

The application uses PostgreSQL as the database, with Prisma as the ORM. Database migrations and initial setup scripts are included in the `prisma` directory.

## Getting Started

To get started with the Komeet application, follow these steps:

1. **Clone the repository**:
   ```
   git clone <repository-url>
   cd komeet
   ```

2. **Set up the mobile application**:
   - Navigate to the `mobile` directory.
   - Run `flutter pub get` to install dependencies.
   - Use `flutter run` to start the application.

3. **Set up the backend server**:
   - Navigate to the `backend` directory.
   - Run `npm install` to install dependencies.
   - Use `npm run start` to start the server.

4. **Database setup**:
   - Ensure PostgreSQL is running.
   - Run the SQL scripts in the `infra/postgres` directory to initialize the database.

## Contributing

Contributions are welcome! Please submit a pull request or open an issue for any enhancements or bug fixes.

## License

This project is licensed under the MIT License. See the LICENSE file for details.