import { Request, Response } from 'express';
import { AuthService } from '../services/auth.service';
import { User } from '../types/index.d';

class AuthController {
  private authService: AuthService;

  constructor() {
    this.authService = new AuthService();
  }

  public async register(req: Request, res: Response): Promise<void> {
    try {
      const user: User = req.body;
      const newUser = await this.authService.register(user);
      res.status(201).json(newUser);
    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  }

  public async login(req: Request, res: Response): Promise<void> {
    try {
      const { email, password } = req.body;
      const token = await this.authService.login(email, password);
      res.status(200).json({ token });
    } catch (error) {
      res.status(401).json({ message: error.message });
    }
  }

  public async logout(req: Request, res: Response): Promise<void> {
    try {
      await this.authService.logout(req.user);
      res.status(204).send();
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  }
}

export default new AuthController();