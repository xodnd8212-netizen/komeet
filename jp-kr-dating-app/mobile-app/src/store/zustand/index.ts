import create from 'zustand';

interface User {
  id: string;
  name: string;
  age: number;
  gender: 'male' | 'female';
  preferences: {
    ageRange: [number, number];
    gender: 'male' | 'female' | 'both';
  };
}

interface Store {
  user: User | null;
  setUser: (user: User) => void;
  clearUser: () => void;
}

export const useStore = create<Store>((set) => ({
  user: null,
  setUser: (user) => set({ user }),
  clearUser: () => set({ user: null }),
}));