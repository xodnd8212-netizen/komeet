import { User } from '../repositories/user.repository';
import { CreateUserDto, UpdateUserDto } from '../schemas/validation';
import { hashPassword, comparePassword } from '../utils/jwt';

class UserService {
  constructor(private userRepository: User) {}

  async createUser(createUserDto: CreateUserDto): Promise<User> {
    const hashedPassword = await hashPassword(createUserDto.password);
    const user = await this.userRepository.create({
      ...createUserDto,
      password: hashedPassword,
    });
    return user;
  }

  async findUserById(userId: string): Promise<User | null> {
    return await this.userRepository.findById(userId);
  }

  async updateUser(userId: string, updateUserDto: UpdateUserDto): Promise<User | null> {
    return await this.userRepository.update(userId, updateUserDto);
  }

  async deleteUser(userId: string): Promise<void> {
    await this.userRepository.delete(userId);
  }

  async validateUserCredentials(email: string, password: string): Promise<User | null> {
    const user = await this.userRepository.findByEmail(email);
    if (user && await comparePassword(password, user.password)) {
      return user;
    }
    return null;
  }
}

export default UserService;