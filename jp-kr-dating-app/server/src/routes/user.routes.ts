import { Router } from 'express';
import { createUser, getUser, updateUser, deleteUser } from '../controllers/user.controller';
import { validateUser } from '../middlewares/validation.middleware';
import { authenticate } from '../middlewares/auth.middleware';

const router = Router();

// Create a new user
router.post('/', validateUser, createUser);

// Get user by ID
router.get('/:id', authenticate, getUser);

// Update user by ID
router.put('/:id', authenticate, validateUser, updateUser);

// Delete user by ID
router.delete('/:id', authenticate, deleteUser);

export default router;