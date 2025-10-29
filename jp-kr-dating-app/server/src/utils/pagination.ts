import { Request, Response } from 'express';

interface PaginationResult<T> {
  data: T[];
  total: number;
  page: number;
  pageSize: number;
}

export const paginate = <T>(
  items: T[],
  page: number,
  pageSize: number
): PaginationResult<T> => {
  const total = items.length;
  const startIndex = (page - 1) * pageSize;
  const endIndex = startIndex + pageSize;
  const data = items.slice(startIndex, endIndex);

  return {
    data,
    total,
    page,
    pageSize,
  };
};

export const paginateMiddleware = (req: Request, res: Response, next: Function) => {
  const { page = 1, pageSize = 10 } = req.query;

  req.pagination = {
    page: Number(page),
    pageSize: Number(pageSize),
  };

  next();
};