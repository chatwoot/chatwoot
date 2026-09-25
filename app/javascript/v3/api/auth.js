import {
  setAuthCredentials,
  throwErrorMessage,
  clearLocalStorageOnLogout,
  parseAPIErrorResponse,
} from 'dashboard/store/utils/api';
import wootAPI from './apiClient';
import {
  getLoginRedirectURL,
  getCredentialsFromEmail,
} from '../helpers/AuthHelper';

export const login = async ({
  ssoAccountId,
  ssoConversationId,
  ...credentials
}) => {
  try {
    const response = await wootAPI.post('auth/sign_in', credentials);

    // Check if MFA is required
    if (response.status === 206 && response.data.mfa_required) {
      // Return MFA data instead of throwing error
      return {
        mfaRequired: true,
        mfaToken: response.data.mfa_token,
        verificationChannel: response.data.verification_channel,
      };
    }

    // Check if the account enforces MFA and the user must enrol first
    if (response.status === 206 && response.data.mfa_setup_required) {
      return {
        mfaSetupRequired: true,
        mfaSetupToken: response.data.mfa_setup_token,
        provisioningUrl: response.data.provisioning_url,
        secret: response.data.secret,
      };
    }

    setAuthCredentials(response);
    clearLocalStorageOnLogout();
    window.location = getLoginRedirectURL({
      ssoAccountId,
      ssoConversationId,
      user: response.data.data,
    });
    return null;
  } catch (error) {
    // Check if it's an MFA required response
    if (error.response?.status === 206 && error.response?.data?.mfa_required) {
      return {
        mfaRequired: true,
        mfaToken: error.response.data.mfa_token,
        verificationChannel: error.response.data.verification_channel,
      };
    }
    if (
      error.response?.status === 206 &&
      error.response?.data?.mfa_setup_required
    ) {
      return {
        mfaSetupRequired: true,
        mfaSetupToken: error.response.data.mfa_setup_token,
        provisioningUrl: error.response.data.provisioning_url,
        secret: error.response.data.secret,
      };
    }
    if (
      error.response?.status === 409 &&
      error.response?.data?.sessions_limit_reached
    ) {
      return {
        sessionsLimitReached: true,
        sessions: error.response.data.sessions,
      };
    }
    const loginError = new Error(parseAPIErrorResponse(error));
    loginError.errorCode = error.response?.data?.error_code;
    throw loginError;
  }
};

export const register = async creds => {
  try {
    const { fullName, accountName } = getCredentialsFromEmail(creds.email);
    const response = await wootAPI.post('api/v1/accounts.json', {
      account_name: accountName,
      user_full_name: fullName,
      email: creds.email,
      password: creds.password,
      h_captcha_client_response: creds.hCaptchaClientResponse,
    });
    return response.data;
  } catch (error) {
    throwErrorMessage(error);
  }
  return null;
};

export const resendConfirmation = async ({ email, hCaptchaClientResponse }) => {
  return wootAPI.post('resend_confirmation', {
    email,
    h_captcha_client_response: hCaptchaClientResponse,
  });
};

export const verifyPasswordToken = async ({ confirmationToken }) => {
  try {
    const response = await wootAPI.post('auth/confirmation', {
      confirmation_token: confirmationToken,
    });
    // Accounts enforcing MFA respond without session tokens; the user must
    // sign in so the MFA setup flow can run.
    if (response.data?.redirect_url) {
      return { redirectUrl: response.data.redirect_url };
    }
    setAuthCredentials(response);
    return {};
  } catch (error) {
    return throwErrorMessage(error);
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
    // Accounts enforcing MFA respond without session tokens; the user must
    // sign in so the MFA setup flow can run.
    if (response.data?.redirect_url) {
      return { redirectUrl: response.data.redirect_url };
    }
    setAuthCredentials(response);
    return {};
  } catch (error) {
    return throwErrorMessage(error);
  }
};

export const resetPassword = async ({ email }) =>
  wootAPI.post('auth/password', { email });
