import { User } from '../types/user';
import { sign, verify } from 'jsonwebtoken';
import { prisma } from '../prisma/client';
import { AuthPayload } from '../types/auth';
import { BadRequestError, UnauthorizedError } from '../utils/errors';

const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret';

export const register = async (userData: User): Promise<AuthPayload> => {
    const existingUser = await prisma.user.findUnique({
        where: { email: userData.email },
    });

    if (existingUser) {
        throw new BadRequestError('User already exists');
    }

    const user = await prisma.user.create({
        data: userData,
    });

    const token = sign({ id: user.id }, JWT_SECRET, { expiresIn: '1h' });

    return { user, token };
};

export const login = async (email: string, password: string): Promise<AuthPayload> => {
    const user = await prisma.user.findUnique({
        where: { email },
    });

    if (!user || user.password !== password) {
        throw new UnauthorizedError('Invalid credentials');
    }

    const token = sign({ id: user.id }, JWT_SECRET, { expiresIn: '1h' });

    return { user, token };
};

export const verifyToken = (token: string): Promise<any> => {
    return new Promise((resolve, reject) => {
        verify(token, JWT_SECRET, (err, decoded) => {
            if (err) {
                return reject(new UnauthorizedError('Invalid token'));
            }
            resolve(decoded);
        });
    });
};