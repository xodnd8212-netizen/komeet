import { Request, Response } from 'express';
import { UserService } from '../services/users.service';
import { User } from '../types/index.d';

export class UsersController {
  private userService: UserService;

  constructor() {
    this.userService = new UserService();
  }

  public async getAllUsers(req: Request, res: Response): Promise<void> {
    try {
      const users: User[] = await this.userService.getAllUsers();
      res.status(200).json(users);
    } catch (error) {
      res.status(500).json({ message: 'Error retrieving users', error });
    }
  }

  public async getUserById(req: Request, res: Response): Promise<void> {
    const userId = req.params.id;
    try {
      const user: User | null = await this.userService.getUserById(userId);
      if (user) {
        res.status(200).json(user);
      } else {
        res.status(404).json({ message: 'User not found' });
      }
    } catch (error) {
      res.status(500).json({ message: 'Error retrieving user', error });
    }
  }

  public async createUser(req: Request, res: Response): Promise<void> {
    const newUser: User = req.body;
    try {
      const createdUser: User = await this.userService.createUser(newUser);
      res.status(201).json(createdUser);
    } catch (error) {
      res.status(500).json({ message: 'Error creating user', error });
    }
  }

  public async updateUser(req: Request, res: Response): Promise<void> {
    const userId = req.params.id;
    const updatedUser: User = req.body;
    try {
      const user: User | null = await this.userService.updateUser(userId, updatedUser);
      if (user) {
        res.status(200).json(user);
      } else {
        res.status(404).json({ message: 'User not found' });
      }
    } catch (error) {
      res.status(500).json({ message: 'Error updating user', error });
    }
  }

  public async deleteUser(req: Request, res: Response): Promise<void> {
    const userId = req.params.id;
    try {
      const deleted = await this.userService.deleteUser(userId);
      if (deleted) {
        res.status(204).send();
      } else {
        res.status(404).json({ message: 'User not found' });
      }
    } catch (error) {
      res.status(500).json({ message: 'Error deleting user', error });
    }
  }
}