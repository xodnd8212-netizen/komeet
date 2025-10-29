import { z } from 'zod';

export const userSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1).max(100),
  age: z.number().min(18).max(100),
  gender: z.enum(['male', 'female']),
  nationality: z.enum(['Korean', 'Japanese']),
  interests: z.array(z.string()).optional(),
});

export const signUpSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  confirmPassword: z.string().min(8).refine((val, ctx) => {
    if (val !== ctx.parent.password) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "Passwords don't match",
      });
      return false;
    }
    return true;
  }),
});

export const signInSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

export const matchSchema = z.object({
  userId: z.string().uuid(),
  matchedUserId: z.string().uuid(),
  status: z.enum(['pending', 'accepted', 'rejected']),
});