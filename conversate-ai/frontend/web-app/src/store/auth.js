import { defineStore } from 'pinia';
import identityAPI from '../api/identity';

export const useAuthStore = defineStore('auth', {
  state: () => ({
    token: localStorage.getItem('authToken') || null,
    user: null,
    isAuthenticated: !!localStorage.getItem('authToken'),
  }),

  actions: {
    async login(email, password) {
      try {
        const response = await identityAPI.login(email, password);
        const token = response.data.access_token;

        this.token = token;
        this.isAuthenticated = true;
        localStorage.setItem('authToken', token);

        // After getting the token, fetch the user's data
        await this.fetchUser();

        return true;
      } catch (error) {
        console.error('Login failed:', error);
        this.logout();
        return false;
      }
    },

    async fetchUser() {
      if (!this.token) return;
      try {
        const response = await identityAPI.getMe();
        this.user = response.data;
      } catch (error) {
        console.error('Failed to fetch user:', error);
        this.logout(); // If we can't get the user, log out
      }
    },

    async register(email, password, accountName) {
      try {
        // 1. Create the account
        const accResponse = await identityAPI.createAccount(accountName);
        const accountId = accResponse.data.id;

        // 2. Create the user
        await identityAPI.register(email, password, accountId);

        // 3. Log the user in
        return await this.login(email, password);
      } catch (error) {
        console.error('Registration failed:', error);
        return false;
      }
    },

    logout() {
      this.token = null;
      this.user = null;
      this.isAuthenticated = false;
      localStorage.removeItem('authToken');
      // In a real app, we'd also want to redirect to the login page.
    },
  },

  getters: {
    // You can add getters here if needed, e.g., for user roles
  },
});
