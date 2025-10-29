import helmet from 'helmet';
import { Request, Response, NextFunction } from 'express';

const helmetMiddleware = (req: Request, res: Response, next: NextFunction) => {
  helmet()(req, res, next);
};

export default helmetMiddleware;