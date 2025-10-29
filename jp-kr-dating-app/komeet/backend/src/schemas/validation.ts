import { z } from 'zod';

export const userSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  age: z.number().min(18, 'You must be at least 18 years old'),
  email: z.string().email('Invalid email address'),
  password: z.string().min(6, 'Password must be at least 6 characters long'),
  preferences: z.object({
    gender: z.enum(['male', 'female', 'other']),
    interests: z.array(z.string()).min(1, 'At least one interest is required'),
  }),
});

export const loginSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(6, 'Password must be at least 6 characters long'),
});

export const profileUpdateSchema = z.object({
  name: z.string().optional(),
  age: z.number().min(18, 'You must be at least 18 years old').optional(),
  preferences: z.object({
    gender: z.enum(['male', 'female', 'other']).optional(),
    interests: z.array(z.string()).optional(),
  }).optional(),
});