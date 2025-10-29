import { z } from 'zod';

export const signUpSchema = z.object({
  username: z.string().min(3, 'Username must be at least 3 characters long'),
  email: z.string().email('Invalid email address'),
  password: z.string().min(6, 'Password must be at least 6 characters long'),
  confirmPassword: z.string().min(6, 'Confirm Password must be at least 6 characters long'),
}).refine(data => data.password === data.confirmPassword, {
  message: "Passwords don't match",
  path: ['confirmPassword'],
});

export const signInSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(6, 'Password must be at least 6 characters long'),
});

export const profileSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  age: z.number().min(18, 'You must be at least 18 years old'),
  bio: z.string().optional(),
  interests: z.array(z.string()).optional(),
});