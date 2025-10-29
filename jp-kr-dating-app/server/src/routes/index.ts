import { Router } from 'express';
import authRoutes from './auth.routes';
import userRoutes from './user.routes';
import matchRoutes from './match.routes';
import uploadRoutes from './upload.routes';

const router = Router();

router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/matches', matchRoutes);
router.use('/upload', uploadRoutes);

export default router;