import { Router } from 'express';
import { createMatch, getMatches, deleteMatch } from '../controllers/match.controller';
import { authenticate } from '../middlewares/auth.middleware';
import { validateMatch } from '../validators/zod-schemas';

const router = Router();

// Create a new match
router.post('/', authenticate, validateMatch, createMatch);

// Get all matches for a user
router.get('/', authenticate, getMatches);

// Delete a match
router.delete('/:id', authenticate, deleteMatch);

export default router;