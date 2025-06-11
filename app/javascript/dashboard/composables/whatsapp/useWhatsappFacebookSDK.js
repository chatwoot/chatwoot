import { useWhatsappSDKHelpers } from './useWhatsappSDKHelpers';
import { useWhatsappAuthCallbacks } from './useWhatsappAuthCallbacks';

export function useWhatsappFacebookSDK({
  fbSdkLoaded,
  hasSignupStarted,
  processingMessage,
  isProcessing,
  isAuthenticating,
  currentStep,
  authCode,
  authCodeReceived,
  businessData,
  completeSignupFlow,
  handleSignupError,
  t,
}) {
  const { createFacebookScript, createLoginOptions } = useWhatsappSDKHelpers();

  const { fbLoginCallback } = useWhatsappAuthCallbacks({
    authCode,
    authCodeReceived,
    currentStep,
    processingMessage,
    isProcessing,
    isAuthenticating,
    hasSignupStarted,
    businessData,
    completeSignupFlow,
    handleSignupError,
    t,
  });

  const loadFacebookSdk = () => {
    if (window.FB) {
      fbSdkLoaded.value = true;
      return;
    }
    createFacebookScript(fbSdkLoaded);
  };

  const setSignupProcessingState = () => {
    hasSignupStarted.value = true;
    processingMessage.value = t(
      'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.AUTH_PROCESSING'
    );
  };

  const executeSignup = () => {
    isAuthenticating.value = true;
    currentStep.value = 'auth_processing';
    const options = createLoginOptions();
    window.FB.login(fbLoginCallback, options);
  };

  const launchEmbeddedSignup = () => {
    setSignupProcessingState();

    if (!window.FB) {
      loadFacebookSdk();
      setTimeout(() => launchEmbeddedSignup(), 1000);
      return;
    }

    executeSignup();
  };

  return {
    loadFacebookSdk,
    launchEmbeddedSignup,
  };
}
