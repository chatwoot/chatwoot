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
  const loadFacebookSdk = () => {
    if (window.FB) {
      fbSdkLoaded.value = true;
      return;
    }

    const script = document.createElement('script');
    script.src = 'https://connect.facebook.net/en_US/sdk.js';
    script.async = true;
    script.defer = true;
    script.onload = () => {
      window.FB.init({
        appId: window.chatwootConfig?.whatsappAppId,
        status: true,
        xfbml: true,
        version: window.chatwootConfig?.whatsappApiVersion || 'v22.0',
      });
      fbSdkLoaded.value = true;
    };
    document.body.appendChild(script);
  };

  const fbLoginCallback = response => {
    if (response.authResponse && response.authResponse.code) {
      authCode.value = response.authResponse.code;
      authCodeReceived.value = true;
      currentStep.value = 'auth_received';
      processingMessage.value = t(
        'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.WAITING_FOR_BUSINESS_INFO'
      );

      if (businessData.value) {
        completeSignupFlow(businessData.value);
      }
    } else if (response.error) {
      handleSignupError({ error: response.error });
    } else {
      currentStep.value = 'initial';
      isProcessing.value = false;
      isAuthenticating.value = false;
      hasSignupStarted.value = false;
      useAlert(t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.CANCELLED'));
    }
  };

  const launchEmbeddedSignup = () => {
    hasSignupStarted.value = true;
    processingMessage.value = t(
      'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.AUTH_PROCESSING'
    );

    if (!window.FB) {
      loadFacebookSdk();
      setTimeout(() => launchEmbeddedSignup(), 1000);
      return;
    }

    isAuthenticating.value = true;
    currentStep.value = 'auth_processing';

    window.FB.login(fbLoginCallback, {
      config_id: window.chatwootConfig?.whatsappConfigurationId,
      response_type: 'code',
      override_default_response_type: true,
      extras: {
        setup: {},
        featureType: '',
        sessionInfoVersion: '3',
      },
    });
  };

  return {
    loadFacebookSdk,
    launchEmbeddedSignup,
  };
}
