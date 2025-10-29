import { User } from '../repositories/user.repository';
import { sign, verify } from '../utils/jwt';
import { BadRequestError, UnauthorizedError } from '../middlewares/error.middleware';

class AuthService {
  async register(userData: User) {
    // Validate user data and check if user already exists
    const existingUser = await User.findByEmail(userData.email);
    if (existingUser) {
      throw new BadRequestError('User already exists');
    }

    // Create new user
    const newUser = await User.create(userData);
    return newUser;
  }

  async login(email: string, password: string) {
    // Find user by email
    const user = await User.findByEmail(email);
    if (!user || !(await user.comparePassword(password))) {
      throw new UnauthorizedError('Invalid email or password');
    }

    // Generate JWT token
    const token = sign({ id: user.id });
    return { user, token };
  }

  async verifyToken(token: string) {
    try {
      const decoded = verify(token);
      return decoded;
    } catch (error) {
      throw new UnauthorizedError('Invalid token');
    }
  }
}

export default new AuthService();