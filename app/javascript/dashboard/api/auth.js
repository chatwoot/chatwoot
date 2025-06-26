/* global axios */

import Cookies from 'js-cookie';
import endPoints from './endPoints';
import {
  clearCookiesOnLogout,
  deleteIndexedDBOnLogout,
} from '../store/utils/api';

export default {
  async validityCheck() {
    if (this.hasAuthToken()) {
      const urlData = endPoints('profileUpdate');
      const response = await axios.get(urlData.url);
      // to match the response signature of the validityCheck endpoint
      return Promise.resolve({ data: { payload: response } });
    }

    const urlData = endPoints('validityCheck');
    return axios.get(urlData.url);
  },
  logout() {
    const urlData = endPoints('logout');
    const fetchPromise = new Promise((resolve, reject) => {
      axios
        .delete(urlData.url)
        .then(response => {
          deleteIndexedDBOnLogout();
          clearCookiesOnLogout();
          resolve(response);
        })
        .catch(error => {
          reject(error);
        });
    });
    return fetchPromise;
  },
  hasAuthCookie() {
    return !!Cookies.get('cw_d_session_info');
  },
  hasAuthToken() {
    // eslint-disable-next-line no-underscore-dangle
    return !!window.__WOOT_ACCESS_TOKEN__;
  },
  getAuthData() {
    if (this.hasAuthCookie()) {
      const savedAuthInfo = Cookies.get('cw_d_session_info');
      return JSON.parse(savedAuthInfo || '{}');
    }
    return false;
  },
  profileUpdate({ displayName, avatar, ...profileAttributes }) {
    const formData = new FormData();
    Object.keys(profileAttributes).forEach(key => {
      const hasValue = profileAttributes[key] === undefined;
      if (!hasValue) {
        formData.append(`profile[${key}]`, profileAttributes[key]);
      }
    });
    formData.append('profile[display_name]', displayName || '');
    if (avatar) {
      formData.append('profile[avatar]', avatar);
    }
    return axios.put(endPoints('profileUpdate').url, formData);
  },

  profilePasswordUpdate({ currentPassword, password, passwordConfirmation }) {
    return axios.put(endPoints('profileUpdate').url, {
      profile: {
        current_password: currentPassword,
        password,
        password_confirmation: passwordConfirmation,
      },
    });
  },

  updateUISettings({ uiSettings }) {
    return axios.put(endPoints('profileUpdate').url, {
      profile: { ui_settings: uiSettings },
    });
  },

  updateAvailability(availabilityData) {
    return axios.post(endPoints('availabilityUpdate').url, {
      profile: { ...availabilityData },
    });
  },

  updateAutoOffline(accountId, autoOffline = false) {
    return axios.post(endPoints('autoOffline').url, {
      profile: { account_id: accountId, auto_offline: autoOffline },
    });
  },

  deleteAvatar() {
    return axios.delete(endPoints('deleteAvatar').url);
  },

  resetPassword({ email }) {
    const urlData = endPoints('resetPassword');
    return axios.post(urlData.url, { email });
  },

  setActiveAccount({ accountId }) {
    const urlData = endPoints('setActiveAccount');
    return axios.put(urlData.url, {
      profile: {
        account_id: accountId,
      },
    });
  },
  resendConfirmation() {
    const urlData = endPoints('resendConfirmation');
    return axios.post(urlData.url);
  },
  resetAccessToken() {
    const urlData = endPoints('resetAccessToken');
    return axios.post(urlData.url);
  },
};
