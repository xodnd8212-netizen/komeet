import request from 'supertest';
import app from '../src/app'; // Adjust the import based on your app structure
import { createUser, loginUser } from '../src/services/auth.service'; // Adjust the import based on your service structure

describe('Authentication Tests', () => {
  let user;

  beforeAll(async () => {
    user = await createUser({
      username: 'testuser',
      password: 'testpassword',
      email: 'testuser@example.com',
    });
  });

  afterAll(async () => {
    // Clean up the test user if necessary
  });

  it('should register a new user', async () => {
    const response = await request(app)
      .post('/api/auth/register')
      .send({
        username: 'newuser',
        password: 'newpassword',
        email: 'newuser@example.com',
      });

    expect(response.status).toBe(201);
    expect(response.body).toHaveProperty('token');
  });

  it('should login an existing user', async () => {
    const response = await request(app)
      .post('/api/auth/login')
      .send({
        username: user.username,
        password: 'testpassword',
      });

    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('token');
  });

  it('should fail to login with incorrect password', async () => {
    const response = await request(app)
      .post('/api/auth/login')
      .send({
        username: user.username,
        password: 'wrongpassword',
      });

    expect(response.status).toBe(401);
    expect(response.body).toHaveProperty('message', 'Invalid credentials');
  });
});