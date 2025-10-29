import axios from '../api/axios';

const API_URL = '/auth/';

const authService = {
  signIn: async (email: string, password: string) => {
    const response = await axios.post(`${API_URL}signin`, { email, password });
    if (response.data) {
      localStorage.setItem('user', JSON.stringify(response.data));
    }
    return response.data;
  },

  signUp: async (name: string, email: string, password: string) => {
    const response = await axios.post(`${API_URL}signup`, { name, email, password });
    return response.data;
  },

  logout: () => {
    localStorage.removeItem('user');
  },

  getCurrentUser: () => {
    return JSON.parse(localStorage.getItem('user') || '{}');
  },
};

export default authService;