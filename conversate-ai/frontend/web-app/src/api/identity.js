import apiClient from './index';

const identityAPI = {
  login(email, password) {
    // The Identity Service expects form data for the token endpoint
    const formData = new FormData();
    formData.append('username', email);
    formData.append('password', password);

    return apiClient.post('/identity/token', formData, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    });
  },

  register(email, password, accountId) {
    // This assumes the Identity Service is mounted at /identity
    return apiClient.post('/identity/users/', {
      email,
      password,
      account_id: accountId,
    });
  },

  getMe() {
    return apiClient.get('/identity/users/me/');
  },

  createAccount(name) {
    return apiClient.post('/identity/accounts/', { name });
  }
};

export default identityAPI;
