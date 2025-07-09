import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Auth from 'dashboard/api/auth';

export function useWhatsappReauthorization(inboxId) {
  const store = useStore();
  const router = useRouter();
  const { t } = useI18n();

  // State
  const fbSdkLoaded = ref(false);
  const isProcessing = ref(false);
  const processingMessage = ref('');
  const authCodeReceived = ref(false);
  const authCode = ref(null);
  const businessData = ref(null);
  const isAuthenticating = ref(false);

  // Computed
  const authHeaders = computed(() => {
    if (Auth.hasAuthCookie()) {
      const {
        'access-token': accessToken,
        'token-type': tokenType,
        client,
        expiry,
        uid,
      } = Auth.getAuthData();
      return {
        'access-token': accessToken,
        'token-type': tokenType,
        client,
        expiry,
        uid,
      };
    }
    return {};
  });

  const showLoader = computed(
    () => isAuthenticating.value || isProcessing.value
  );

  // Error handling
  const handleReauthorizationError = data => {
    isProcessing.value = false;
    authCodeReceived.value = false;
    isAuthenticating.value = false;

    const errorMessage =
      data.error ||
      data.message ||
      t('INBOX_MGMT.SETTINGS.WHATSAPP_REAUTHORIZE.ERROR');
    useAlert(errorMessage);
  };

  const handleReauthorizationCancellation = () => {
    isProcessing.value = false;
    authCodeReceived.value = false;
    isAuthenticating.value = false;

    useAlert(t('INBOX_MGMT.SETTINGS.WHATSAPP_REAUTHORIZE.CANCELLED'));
  };

  const handleReauthorizationSuccess = async () => {
    isProcessing.value = false;
    isAuthenticating.value = false;

    // Refresh the inbox to update reauthorization status
    await store.dispatch('inboxes/get');
    useAlert(t('INBOX_MGMT.SETTINGS.WHATSAPP_REAUTHORIZE.SUCCESS'));

    // Reload the page to reflect the changes
    router.go(0);
  };

  // Reauthorization flow
  const completeReauthorizationFlow = async businessDataParam => {
    if (!authCodeReceived.value || !authCode.value) {
      handleReauthorizationError({
        error: t('INBOX_MGMT.SETTINGS.WHATSAPP_REAUTHORIZE.AUTH_NOT_COMPLETED'),
      });
      return;
    }

    isProcessing.value = true;
    processingMessage.value = t(
      'INBOX_MGMT.SETTINGS.WHATSAPP_REAUTHORIZE.PROCESSING'
    );

    try {
      // Send reauthorization request
      const accountId = store.getters.getCurrentAccountId;
      const response = await fetch('/whatsapp/reauthorize', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document
            .querySelector('meta[name="csrf-token"]')
            ?.getAttribute('content'),
          ...authHeaders.value,
        },
        body: JSON.stringify({
          account_id: accountId,
          inbox_id: inboxId,
          code: authCode.value,
          business_id: businessDataParam.business_id,
          waba_id: businessDataParam.waba_id,
          phone_number_id: businessDataParam.phone_number_id,
        }),
      });

      const responseData = await response.json();

      if (response.ok) {
        // Clear the stored auth code for security
        authCode.value = null;

        // Handle synchronous success response
        handleReauthorizationSuccess();
      } else {
        throw new Error(responseData.message || responseData.error);
      }
    } catch (error) {
      handleReauthorizationError({ error: error.message });
    }
  };

  const isValidBusinessData = businessDataLocal => {
    return (
      businessDataLocal &&
      (businessDataLocal.business_id || businessDataLocal.businessId) &&
      (businessDataLocal.waba_id || businessDataLocal.wabaId)
    );
  };

  // Message handling
  const handleEmbeddedSignupData = async data => {
    // Handle different embedded signup events per Facebook documentation
    if (data.event === 'FINISH') {
      // Facebook might send business data in different structures
      let businessDataLocal = data.data;

      // If data.data doesn't exist, try other possible structures
      if (!businessDataLocal) {
        businessDataLocal = data.business_data || data.details || data;
      }

      // Validate we have the required business information
      if (isValidBusinessData(businessDataLocal)) {
        // Normalize the data structure to match our backend expectations
        const normalizedData = {
          business_id:
            businessDataLocal.business_id || businessDataLocal.businessId,
          waba_id: businessDataLocal.waba_id || businessDataLocal.wabaId,
          phone_number_id:
            businessDataLocal.phone_number_id ||
            businessDataLocal.phoneNumberId ||
            businessDataLocal.phone_id,
        };

        // Store business data
        businessData.value = normalizedData;
        // Check if we already have auth code and process immediately
        if (authCodeReceived.value && authCode.value) {
          await completeReauthorizationFlow(normalizedData);
        } else {
          processingMessage.value = t(
            'INBOX_MGMT.SETTINGS.WHATSAPP_REAUTHORIZE.WAITING_FOR_AUTH'
          );
        }
      } else {
        handleReauthorizationError({
          error: t(
            'INBOX_MGMT.SETTINGS.WHATSAPP_REAUTHORIZE.INVALID_BUSINESS_DATA'
          ),
        });
      }
    } else if (data.event === 'CANCEL') {
      handleReauthorizationCancellation();
    } else if (data.event === 'error') {
      handleReauthorizationError({
        error:
          data.error_message ||
          t('INBOX_MGMT.SETTINGS.WHATSAPP_REAUTHORIZE.ERROR'),
      });
    }
  };

  const fbLoginCallback = response => {
    if (response.authResponse && response.authResponse.code) {
      // Authorization code received from Facebook
      authCode.value = response.authResponse.code;
      authCodeReceived.value = true;
      processingMessage.value = t(
        'INBOX_MGMT.SETTINGS.WHATSAPP_REAUTHORIZE.WAITING_FOR_BUSINESS_INFO'
      );

      // Check if we already have business data and process immediately
      if (businessData.value) {
        completeReauthorizationFlow(businessData.value);
      }
    } else if (response.error) {
      handleReauthorizationError({ error: response.error });
    } else {
      isProcessing.value = false;
      isAuthenticating.value = false;
      useAlert(t('INBOX_MGMT.SETTINGS.WHATSAPP_REAUTHORIZE.CANCELLED'));
    }
  };

  const handleSignupMessage = event => {
    // Handle Facebook embedded signup message events
    try {
      const originUrl = new URL(event.origin);
      const allowedHosts = ['facebook.com', 'www.facebook.com'];
      if (!allowedHosts.includes(originUrl.hostname)) return;
    } catch (error) {
      // Invalid origin URL, reject the event
      return;
    }

    try {
      const data = JSON.parse(event.data);

      if (data.type === 'WA_EMBEDDED_SIGNUP') {
        handleEmbeddedSignupData(data);
      }
    } catch (error) {
      // Handle non-JSON messages silently
    }
  };

  // Facebook SDK
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

  const launchReauthorization = () => {
    processingMessage.value = t(
      'INBOX_MGMT.SETTINGS.WHATSAPP_REAUTHORIZE.AUTH_PROCESSING'
    );

    if (!window.FB) {
      loadFacebookSdk();
      setTimeout(() => launchReauthorization(), 1000);
      return;
    }

    isAuthenticating.value = true;

    // Following Facebook's embedded signup documentation
    // Using auth_type: 'reauthorize' to force reauthorization
    window.FB.login(fbLoginCallback, {
      config_id: window.chatwootConfig?.whatsappConfigurationId,
      response_type: 'code',
      override_default_response_type: true,
      auth_type: 'reauthorize',
      extras: {
        setup: {},
        featureType: '', // Leave empty for default flow
        sessionInfoVersion: '3',
      },
    });
  };

  // Lifecycle
  const setupMessageListener = () => {
    window.addEventListener('message', handleSignupMessage);
  };

  const cleanupMessageListener = () => {
    window.removeEventListener('message', handleSignupMessage);
  };

  // Initialize
  const initialize = () => {
    loadFacebookSdk();
    setupMessageListener();
  };

  return {
    // State
    fbSdkLoaded,
    isProcessing,
    processingMessage,
    isAuthenticating,

    // Computed
    showLoader,

    // Methods
    launchReauthorization,
    initialize,
    cleanupMessageListener,
  };
}
