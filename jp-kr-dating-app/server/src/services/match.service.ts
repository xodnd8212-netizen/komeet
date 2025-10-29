import { Match } from '../types/match';
import { User } from '../types/user';
import { prisma } from '../prisma/client';

export class MatchService {
    async createMatch(userId: string, matchId: string): Promise<Match> {
        const match = await prisma.match.create({
            data: {
                userId,
                matchId,
            },
        });
        return match;
    }

    async getMatches(userId: string): Promise<Match[]> {
        const matches = await prisma.match.findMany({
            where: {
                userId,
            },
        });
        return matches;
    }

    async deleteMatch(userId: string, matchId: string): Promise<void> {
        await prisma.match.deleteMany({
            where: {
                userId,
                matchId,
            },
        });
    }

    async findMatch(userId: string, matchId: string): Promise<Match | null> {
        const match = await prisma.match.findUnique({
            where: {
                userId_matchId: {
                    userId,
                    matchId,
                },
            },
        });
        return match;
    }

    async getUserMatches(userId: string): Promise<User[]> {
        const matches = await this.getMatches(userId);
        const userMatches = await prisma.user.findMany({
            where: {
                id: {
                    in: matches.map(match => match.matchId),
                },
            },
        });
        return userMatches;
    }
}