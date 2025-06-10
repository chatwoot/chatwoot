import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Auth from 'dashboard/api/auth';

export function useWhatsappEmbeddedSignup() {
  const store = useStore();
  const router = useRouter();
  const { t } = useI18n();

  // State
  const fbSdkLoaded = ref(false);
  const isProcessing = ref(false);
  const processingMessage = ref('');
  const authCodeReceived = ref(false);
  const currentStep = ref('initial');
  const authCode = ref(null);
  const businessData = ref(null);
  const isAuthenticating = ref(false);
  const hasSignupStarted = ref(false);

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

  const benefits = computed(() => [
    {
      key: 'EASY_SETUP',
      text: t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.BENEFITS.EASY_SETUP'),
    },
    {
      key: 'SECURE_AUTH',
      text: t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.BENEFITS.SECURE_AUTH'),
    },
    {
      key: 'AUTO_CONFIG',
      text: t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.BENEFITS.AUTO_CONFIG'),
    },
  ]);

  const showLoader = computed(
    () => hasSignupStarted.value || isProcessing.value
  );

  // Error handling
  const handleSignupError = data => {
    currentStep.value = 'initial';
    isProcessing.value = false;
    authCodeReceived.value = false;
    isAuthenticating.value = false;
    hasSignupStarted.value = false;

    const errorMessage =
      data.error ||
      data.message ||
      t('INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  };

  const handleSignupCancellation = data => {
    currentStep.value = 'initial';
    isProcessing.value = false;
    authCodeReceived.value = false;
    isAuthenticating.value = false;
    hasSignupStarted.value = false;

    let message = t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.CANCELLED');
    if (data.data?.current_step) {
      message += ` (Step: ${data.data.current_step})`;
    }

    useAlert(message);
  };

  const handleSignupSuccess = inboxData => {
    currentStep.value = 'completed';
    isProcessing.value = false;
    isAuthenticating.value = false;

    // Update the store with the new inbox data
    if (inboxData && inboxData.id) {
      // Add the new inbox to the store
      store.commit('inboxes/ADD_INBOXES', inboxData);

      useAlert(t('INBOX_MGMT.FINISH.MESSAGE'));

      router.replace({
        name: 'settings_inboxes_add_agents',
        params: {
          page: 'new',
          inbox_id: inboxData.id,
        },
      });
    } else {
      // Fallback if inbox data is not properly formatted
      useAlert(t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.SUCCESS_FALLBACK'));
      router.replace({
        name: 'settings_inbox_list',
      });
    }
  };

  // Signup flow
  const completeSignupFlow = async businessDataParam => {
    if (!authCodeReceived.value || !authCode.value) {
      handleSignupError({
        error: t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.AUTH_NOT_COMPLETED'),
      });
      return;
    }

    currentStep.value = 'processing';
    isProcessing.value = true;
    processingMessage.value = t(
      'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.PROCESSING'
    );

    try {
      // Send both auth code and business info together (synchronous flow)
      const accountId = store.getters.getCurrentAccountId;
      const response = await fetch('/whatsapp/embedded_signup', {
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
        handleSignupSuccess(responseData);
      } else {
        throw new Error(responseData.message || responseData.error);
      }
    } catch (error) {
      handleSignupError({ error: error.message });
    }
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
      if (
        businessDataLocal &&
        (businessDataLocal.business_id || businessDataLocal.businessId) &&
        (businessDataLocal.waba_id || businessDataLocal.wabaId)
      ) {
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
          await completeSignupFlow(normalizedData);
        } else {
          currentStep.value = 'waiting_for_auth';
          processingMessage.value = t(
            'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.WAITING_FOR_AUTH'
          );
        }
      } else {
        handleSignupError({
          error: t(
            'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.INVALID_BUSINESS_DATA'
          ),
        });
      }
    } else if (data.event === 'CANCEL') {
      handleSignupCancellation(data);
    } else if (data.event === 'error') {
      handleSignupError({
        error:
          data.error_message ||
          t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.SIGNUP_ERROR'),
        error_id: data.error_id,
        session_id: data.session_id,
      });
    }
  };

  const fbLoginCallback = response => {
    if (response.authResponse && response.authResponse.code) {
      // Authorization code received from Facebook
      authCode.value = response.authResponse.code;
      authCodeReceived.value = true;
      currentStep.value = 'auth_received';
      processingMessage.value = t(
        'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.WAITING_FOR_BUSINESS_INFO'
      );

      // Check if we already have business data and process immediately
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
        version: window.chatwootConfig?.fbApiVersion || 'v21.0',
      });
      fbSdkLoaded.value = true;
    };
    document.body.appendChild(script);
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

    // Following Facebook's embedded signup documentation
    window.FB.login(fbLoginCallback, {
      config_id: window.chatwootConfig?.whatsappConfigurationId,
      response_type: 'code',
      override_default_response_type: true,
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
    authCodeReceived,
    currentStep,
    authCode,
    businessData,
    isAuthenticating,
    hasSignupStarted,

    // Computed
    benefits,
    showLoader,

    // Methods
    launchEmbeddedSignup,
    initialize,
    cleanupMessageListener,
  };
}
