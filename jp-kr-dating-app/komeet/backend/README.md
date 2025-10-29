# Komeet Dating App Backend

## Overview
Komeet is a dating application designed to connect users in a seamless and engaging manner. This backend repository provides the necessary APIs and services to support the mobile application.

## Technologies Used
- **Node.js**: JavaScript runtime for building the server.
- **Express**: Web framework for building APIs.
- **TypeScript**: Superset of JavaScript for type safety.
- **Prisma**: ORM for database interactions.
- **PostgreSQL**: Relational database for storing user data.
- **Docker**: Containerization for easy deployment.
- **Jest**: Testing framework for unit and integration tests.

## Project Structure
- **src/**: Contains the main application code.
  - **controllers/**: Logic for handling requests.
  - **routes/**: API route definitions.
  - **services/**: Business logic and data handling.
  - **middlewares/**: Custom middleware for request handling.
  - **schemas/**: Validation schemas for incoming requests.
  - **utils/**: Utility functions.
  - **types/**: TypeScript type definitions.
- **prisma/**: Contains the Prisma schema and migrations.
- **tests/**: Unit and integration tests for the application.
- **Dockerfile**: Docker configuration for the backend service.
- **openapi.yaml**: OpenAPI specification for the API.

## Getting Started
1. **Clone the repository**:
   ```
   git clone https://github.com/yourusername/komeet.git
   cd komeet/backend
   ```

2. **Install dependencies**:
   ```
   npm install
   ```

3. **Set up the database**:
   - Create a PostgreSQL database and update the connection string in the `.env` file.

4. **Run migrations**:
   ```
   npx prisma migrate dev
   ```

5. **Start the server**:
   ```
   npm run start
   ```

## API Documentation
Refer to the `openapi.yaml` file for detailed API documentation.

## Testing
Run tests using:
```
npm run test
```

## Contributing
Contributions are welcome! Please open an issue or submit a pull request for any enhancements or bug fixes.

## License
This project is licensed under the MIT License. See the LICENSE file for details.