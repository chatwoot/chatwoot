export function useWhatsappSDKHelpers() {
  const initializeFacebookSDK = fbSdkLoaded => {
    window.FB.init({
      appId: window.chatwootConfig?.whatsappAppId,
      status: true,
      xfbml: true,
      version: window.chatwootConfig?.whatsappApiVersion || 'v22.0',
    });
    fbSdkLoaded.value = true;
  };

  const createFacebookScript = fbSdkLoaded => {
    const script = document.createElement('script');
    script.src = 'https://connect.facebook.net/en_US/sdk.js';
    script.async = true;
    script.defer = true;
    script.onload = () => initializeFacebookSDK(fbSdkLoaded);
    document.body.appendChild(script);
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

  return {
    initializeFacebookSDK,
    createFacebookScript,
    createLoginOptions,
  };
}
