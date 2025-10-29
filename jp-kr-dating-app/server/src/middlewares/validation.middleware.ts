import { NextFunction, Request, Response } from 'express';
import { z } from 'zod';
import { ZodError } from 'zod';

const validateSchema = (schema: z.ZodSchema) => {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      schema.parse(req.body);
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        return res.status(400).json({
          success: false,
          errors: error.errors,
        });
      }
      next(error);
    }
  };
};

export default validateSchema;