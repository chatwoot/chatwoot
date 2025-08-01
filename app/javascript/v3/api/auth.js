import {
  setAuthCredentials,
  throwErrorMessage,
  clearLocalStorageOnLogout,
} from 'dashboard/store/utils/api';
import wootAPI from './apiClient';
import { getLoginRedirectURL } from '../helpers/AuthHelper';

export const login = async ({
  ssoAccountId,
  ssoConversationId,
  ...credentials
}) => {
  try {
    const response = await wootAPI.post('auth/sign_in', credentials);
    setAuthCredentials(response);
    clearLocalStorageOnLogout();
    window.location = getLoginRedirectURL({
      ssoAccountId,
      ssoConversationId,
      user: response.data.data,
    });
  } catch (error) {
    throwErrorMessage(error);
  }
};

export const register = async creds => {
  try {
    // Check if shop parameter exists and if it's already registered
    if (creds.shop) {
      const checkShopResponse = await wootAPI.get(`dashassist_shopify/standalone/stores/${creds.shop}/exists`);
      if (checkShopResponse.data.exists) {
        throw new Error('SHOP_ALREADY_REGISTERED');
      }
    }

    const response = await wootAPI.post('api/v1/accounts.json', {
      account_name: creds.accountName.trim(),
      user_full_name: creds.fullName.trim(),
      email: creds.email,
      password: creds.password,
      h_captcha_client_response: creds.hCaptchaClientResponse,
      shop: creds.shop
    });
    setAuthCredentials(response);
    return response.data;
  } catch (error) {
    if (error.message === 'SHOP_ALREADY_REGISTERED') {
      throw new Error('This shop is already registered with an account');
    }
    throwErrorMessage(error);
  }
  return null;
};

export const verifyPasswordToken = async ({ confirmationToken }) => {
  try {
    const response = await wootAPI.post('auth/confirmation', {
      confirmation_token: confirmationToken,
    });
    setAuthCredentials(response);
  } catch (error) {
    throwErrorMessage(error);
  }
};

export const setNewPassword = async ({
  resetPasswordToken,
  password,
  confirmPassword,
}) => {
  try {
    const response = await wootAPI.put('auth/password', {
      reset_password_token: resetPasswordToken,
      password_confirmation: confirmPassword,
      password,
    });
    setAuthCredentials(response);
  } catch (error) {
    throwErrorMessage(error);
  }
};

export const resetPassword = async ({ email }) =>
  wootAPI.post('auth/password', { email });
