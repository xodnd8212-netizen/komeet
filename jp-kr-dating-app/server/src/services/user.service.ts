import { User } from '../types/user'; // Adjust the import based on your user type definition
import { prisma } from '../prisma'; // Adjust the import based on your Prisma setup
import { hash, compare } from 'bcrypt';
import { sign } from 'jsonwebtoken';

export class UserService {
    async createUser(data: User): Promise<User> {
        const hashedPassword = await hash(data.password, 10);
        const user = await prisma.user.create({
            data: {
                ...data,
                password: hashedPassword,
            },
        });
        return user;
    }

    async findUserById(userId: string): Promise<User | null> {
        return await prisma.user.findUnique({
            where: { id: userId },
        });
    }

    async findUserByEmail(email: string): Promise<User | null> {
        return await prisma.user.findUnique({
            where: { email },
        });
    }

    async validateUserPassword(email: string, password: string): Promise<boolean> {
        const user = await this.findUserByEmail(email);
        if (!user) return false;
        return await compare(password, user.password);
    }

    async generateAuthToken(userId: string): Promise<string> {
        return sign({ id: userId }, process.env.JWT_SECRET as string, { expiresIn: '1h' });
    }

    // Additional user-related business logic can be added here
}