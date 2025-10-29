import { PrismaClient } from '@prisma/client';
import { User } from '../types/index.d';

const prisma = new PrismaClient();

class UserRepository {
  async createUser(data: User): Promise<User> {
    return await prisma.user.create({
      data,
    });
  }

  async getUserById(id: string): Promise<User | null> {
    return await prisma.user.findUnique({
      where: { id },
    });
  }

  async updateUser(id: string, data: Partial<User>): Promise<User> {
    return await prisma.user.update({
      where: { id },
      data,
    });
  }

  async deleteUser(id: string): Promise<User> {
    return await prisma.user.delete({
      where: { id },
    });
  }

  async getAllUsers(): Promise<User[]> {
    return await prisma.user.findMany();
  }
}

export default new UserRepository();