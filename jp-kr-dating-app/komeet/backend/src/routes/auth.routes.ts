import { Router } from 'express';
import { register, login, logout } from '../controllers/auth.controller';
import { validateRegistration, validateLogin } from '../schemas/validation';

const router = Router();

router.post('/register', validateRegistration, register);
router.post('/login', validateLogin, login);
router.post('/logout', logout);

export default router;