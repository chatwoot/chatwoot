/* eslint no-console: 0 */
/* global axios */
/* eslint no-undef: "error" */

import Cookies from 'js-cookie';
import endPoints from './endPoints';
import { setAuthCredentials, clearCookiesOnLogout } from '../store/utils/api';

export default {
  login(creds) {
    return new Promise((resolve, reject) => {
      axios
        .post('auth/sign_in', creds)
        .then(response => {
          setAuthCredentials(response);
          resolve();
        })
        .catch(error => {
          reject(error.response);
        });
    });
  },

  register(creds) {
    const urlData = endPoints('register');
    const fetchPromise = new Promise((resolve, reject) => {
      axios
        .post(urlData.url, {
          account_name: creds.accountName.trim(),
          user_full_name: creds.fullName.trim(),
          email: creds.email,
        })
        .then(response => {
          setAuthCredentials(response);
          resolve(response);
        })
        .catch(error => {
          reject(error);
        });
    });
    return fetchPromise;
  },
  validityCheck() {
    const urlData = endPoints('validityCheck');
    return axios.get(urlData.url);
  },
  logout() {
    const urlData = endPoints('logout');
    const fetchPromise = new Promise((resolve, reject) => {
      axios
        .delete(urlData.url)
        .then(response => {
          clearCookiesOnLogout();
          resolve(response);
        })
        .catch(error => {
          reject(error);
        });
    });
    return fetchPromise;
  },

  isLoggedIn() {
    return !!Cookies.getJSON('auth_data');
  },

  isAdmin() {
    if (this.isLoggedIn()) {
      return Cookies.getJSON('user').role === 'administrator';
    }
    return false;
  },

  getAuthData() {
    if (this.isLoggedIn()) {
      return Cookies.getJSON('auth_data');
    }
    return false;
  },
  getPubSubToken() {
    if (this.isLoggedIn()) {
      return Cookies.getJSON('user').pubsub_token;
    }
    return null;
  },
  getCurrentUser() {
    if (this.isLoggedIn()) {
      return Cookies.getJSON('user');
    }
    return null;
  },

  verifyPasswordToken({ confirmationToken }) {
    return axios.post('auth/confirmation', {
      confirmation_token: confirmationToken,
    });
  },

  setNewPassword({ resetPasswordToken, password, confirmPassword }) {
    return new Promise((resolve, reject) => {
      axios
        .put('auth/password', {
          reset_password_token: resetPasswordToken,
          password_confirmation: confirmPassword,
          password,
        })
        .then(response => {
          setAuthCredentials(response);
          resolve(response);
        })
        .catch(error => {
          reject(error.response);
        });
    });
  },

  resetPassword({ email }) {
    const urlData = endPoints('resetPassword');
    return axios.post(urlData.url, { email });
  },

  profileUpdate({
    password,
    password_confirmation,
    displayName,
    ...profileAttributes
  }) {
    const formData = new FormData();
    Object.keys(profileAttributes).forEach(key => {
      const value = profileAttributes[key];
      if (value) {
        formData.append(`profile[${key}]`, value);
      }
    });
    formData.append('profile[display_name]', displayName || '');
    if (password && password_confirmation) {
      formData.append('profile[password]', password);
      formData.append('profile[password_confirmation]', password_confirmation);
    }
    return axios.put(endPoints('profileUpdate').url, formData);
  },

  updateUISettings({ uiSettings }) {
    return axios.put(endPoints('profileUpdate').url, {
      profile: { ui_settings: uiSettings },
    });
  },

  updateAvailability({ availability }) {
    return axios.put(endPoints('profileUpdate').url, {
      profile: { availability },
    });
  },
};
