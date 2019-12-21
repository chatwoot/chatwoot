/* eslint no-console: 0 */
/* global axios */
/* eslint no-undef: "error" */
/* eslint-env browser */
/* eslint no-unused-expressions: ["error", { "allowShortCircuit": true }] */

import moment from 'moment';
import Cookies from 'js-cookie';
import endPoints from './endPoints';
import { frontendURL } from '../helper/URLHelper';

const setAuthCredentials = response => {
  const expiryDate = moment.unix(response.headers.expiry);
  Cookies.set('auth_data', response.headers, {
    expires: expiryDate.diff(moment(), 'days'),
  });
  Cookies.set('user', response.data.data, {
    expires: expiryDate.diff(moment(), 'days'),
  });
};

const clearCookiesOnLogout = () => {
  Cookies.remove('auth_data');
  Cookies.remove('user');
  window.location = frontendURL('login');
};

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
          account_name: creds.name,
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
    const fetchPromise = new Promise((resolve, reject) => {
      axios
        .get(urlData.url)
        .then(response => {
          resolve(response);
        })
        .catch(error => {
          if (error.response.status === 401) {
            clearCookiesOnLogout();
          }
          reject(error);
        });
    });
    return fetchPromise;
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
          const expiryDate = moment.unix(response.headers.expiry);
          Cookies.set('auth_data', response.headers, {
            expires: expiryDate.diff(moment(), 'days'),
          });
          Cookies.set('user', response.data.data, {
            expires: expiryDate.diff(moment(), 'days'),
          });
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
};
