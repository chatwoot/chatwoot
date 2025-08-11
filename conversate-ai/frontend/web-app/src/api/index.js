import axios from 'axios';
// import { useAuthStore } from '../store/auth'; // Will be created in a later step

const apiClient = axios.create({
  baseURL: '/api', // This will be proxied by Vite to our backend gateway
});

// --- JWT Interceptor ---
// This interceptor will run before each request is sent.
apiClient.interceptors.request.use(
  (config) => {
    // In a real app, we would get the token from our Pinia store
    // const authStore = useAuthStore();
    // const token = authStore.token;

    // For now, we'll use a placeholder or check local storage
    const token = localStorage.getItem('authToken');

    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

export default apiClient;
