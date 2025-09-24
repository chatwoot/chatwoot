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
    const response = await wootAPI.post('api/v1/accounts.json', {
      account_name: creds.accountName.trim(),
      user_full_name: creds.fullName.trim(),
      email: creds.email,
      password: creds.password,
      phoneNumber: creds.phoneNumber,
      h_captcha_client_response: creds.hCaptchaClientResponse,
    });
    // Don't set auth credentials - user needs to verify email first
    // setAuthCredentials(response);
    return response.data;
  } catch (error) {
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

// OTP related functions
export const generateOTP = async ({ email }) => {
  try {
    const response = await wootAPI.post('api/v1/otp/generate', { email });
    return response.data;
  } catch (error) {
    throwErrorMessage(error);
  }
};

export const verifyOTP = async ({ email, code }) => {
  try {
    const response = await wootAPI.post('api/v1/otp/verify', { email, code });
    return response.data;
  } catch (error) {
    throwErrorMessage(error);
  }
};

export const resendOTP = async ({ email }) => {
  try {
    const response = await wootAPI.post('api/v1/otp/resend', { email });
    return response.data;
  } catch (error) {
    throwErrorMessage(error);
  }
};
