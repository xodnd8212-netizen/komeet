import axios from 'axios';

const api = axios.create({
  baseURL: 'https://your-api-url.com/api', // Replace with your API base URL
  timeout: 10000, // Set a timeout for requests
});

// Add a request interceptor
api.interceptors.request.use(
  (config) => {
    // You can add authorization tokens or other headers here
    const token = localStorage.getItem('token'); // Example: get token from local storage
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Add a response interceptor
api.interceptors.response.use(
  (response) => {
    return response.data; // Return only the data from the response
  },
  (error) => {
    // Handle errors globally
    console.error('API Error:', error);
    return Promise.reject(error);
  }
);

export default api;