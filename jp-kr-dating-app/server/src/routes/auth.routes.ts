import { Router } from 'express';
import { signIn, signUp } from '../controllers/auth.controller';
import { validateSignIn, validateSignUp } from '../validators/zod-schemas';

const router = Router();

router.post('/signin', validateSignIn, signIn);
router.post('/signup', validateSignUp, signUp);

export default router;