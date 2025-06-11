import { useAlert } from 'dashboard/composables';

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
  const initializeFacebookSDK = () => {
    window.FB.init({
      appId: window.chatwootConfig?.whatsappAppId,
      status: true,
      xfbml: true,
      version: window.chatwootConfig?.whatsappApiVersion || 'v22.0',
    });
    fbSdkLoaded.value = true;
  };

  const createFacebookScript = () => {
    const script = document.createElement('script');
    script.src = 'https://connect.facebook.net/en_US/sdk.js';
    script.async = true;
    script.defer = true;
    script.onload = initializeFacebookSDK;
    document.body.appendChild(script);
  };

  const loadFacebookSdk = () => {
    if (window.FB) {
      fbSdkLoaded.value = true;
      return;
    }
    createFacebookScript();
  };

  const handleSuccessfulAuth = authResponse => {
    authCode.value = authResponse.code;
    authCodeReceived.value = true;
    currentStep.value = 'auth_received';
    processingMessage.value = t(
      'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.WAITING_FOR_BUSINESS_INFO'
    );

    if (businessData.value) {
      completeSignupFlow(businessData.value);
    }
  };

  const handleAuthError = error => {
    handleSignupError({ error });
  };

  const handleAuthCancellation = () => {
    currentStep.value = 'initial';
    isProcessing.value = false;
    isAuthenticating.value = false;
    hasSignupStarted.value = false;
    useAlert(t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.CANCELLED'));
  };

  const fbLoginCallback = response => {
    if (response.authResponse?.code) {
      handleSuccessfulAuth(response.authResponse);
    } else if (response.error) {
      handleAuthError(response.error);
    } else {
      handleAuthCancellation();
    }
  };

  const setSignupProcessingState = () => {
    hasSignupStarted.value = true;
    processingMessage.value = t(
      'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.AUTH_PROCESSING'
    );
  };

  const setAuthenticatingState = () => {
    isAuthenticating.value = true;
    currentStep.value = 'auth_processing';
  };

  const createLoginOptions = () => ({
    config_id: window.chatwootConfig?.whatsappConfigurationId,
    response_type: 'code',
    override_default_response_type: true,
    extras: {
      setup: {},
      featureType: '',
      sessionInfoVersion: '3',
    },
  });

  const executeSignup = () => {
    setAuthenticatingState();
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
