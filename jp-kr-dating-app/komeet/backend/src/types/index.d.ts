// This file defines TypeScript types used in the backend.

export interface User {
  id: string;
  name: string;
  age: number;
  gender: 'male' | 'female' | 'other';
  preferences: {
    ageRange: [number, number];
    gender: 'male' | 'female' | 'other' | 'any';
  };
  profilePictureUrl?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface Match {
  id: string;
  userId1: string;
  userId2: string;
  matchedAt: Date;
}

export interface AuthResponse {
  token: string;
  user: User;
}

export interface ErrorResponse {
  message: string;
  code?: number;
}