import { computed } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useWhatsappSignupValidation } from './whatsapp/useWhatsappSignupValidation';
import { useWhatsappSignupState } from './whatsapp/useWhatsappSignupState';
import { useWhatsappSignupHandlers } from './whatsapp/useWhatsappSignupHandlers';
import { useWhatsappSignupApi } from './whatsapp/useWhatsappSignupApi';
import { useWhatsappFacebookSDK } from './whatsapp/useWhatsappFacebookSDK';

export function useWhatsappEmbeddedSignup() {
  const store = useStore();
  const router = useRouter();
  const { t } = useI18n();

  // Composables
  const { isValidBusinessData, normalizeBusinessData } =
    useWhatsappSignupValidation();

  const {
    fbSdkLoaded,
    isProcessing,
    processingMessage,
    authCodeReceived,
    currentStep,
    authCode,
    businessData,
    isAuthenticating,
    hasSignupStarted,
    resetState,
  } = useWhatsappSignupState();

  const { handleSignupError, handleSignupCancellation, handleSignupSuccess } =
    useWhatsappSignupHandlers({
      currentStep,
      isProcessing,
      isAuthenticating,
      resetState,
      store,
      router,
      t,
    });

  const { completeSignupFlow } = useWhatsappSignupApi({
    authCodeReceived,
    authCode,
    currentStep,
    isProcessing,
    processingMessage,
    store,
    t,
    handleSignupError,
    handleSignupSuccess,
  });

  const { loadFacebookSdk, launchEmbeddedSignup } = useWhatsappFacebookSDK({
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
  });

  // Computed
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

  // Message handling
  const handleEmbeddedSignupData = async data => {
    if (data.event === 'FINISH') {
      const businessDataLocal =
        data.data || data.business_data || data.details || data;

      if (isValidBusinessData(businessDataLocal)) {
        const normalizedData = normalizeBusinessData(businessDataLocal);
        businessData.value = normalizedData;

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

  const handleSignupMessage = event => {
    try {
      const originUrl = new URL(event.origin);
      const allowedHosts = ['facebook.com', 'www.facebook.com'];
      if (!allowedHosts.includes(originUrl.hostname)) return;
    } catch (error) {
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

  // Lifecycle
  const setupMessageListener = () => {
    window.addEventListener('message', handleSignupMessage);
  };

  const cleanupMessageListener = () => {
    window.removeEventListener('message', handleSignupMessage);
  };

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
