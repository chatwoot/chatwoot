import { computed } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useWhatsappSignupValidation } from './whatsapp/useWhatsappSignupValidation';
import { useWhatsappSignupState } from './whatsapp/useWhatsappSignupState';
import { useWhatsappSignupHandlers } from './whatsapp/useWhatsappSignupHandlers';
import { useWhatsappSignupApi } from './whatsapp/useWhatsappSignupApi';
import { useWhatsappFacebookSDK } from './whatsapp/useWhatsappFacebookSDK';
import { useWhatsappMessageHandler } from './whatsapp/useWhatsappMessageHandler';

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

  const { handleSignupMessage } = useWhatsappMessageHandler({
    isValidBusinessData,
    normalizeBusinessData,
    businessData,
    authCodeReceived,
    authCode,
    completeSignupFlow,
    currentStep,
    processingMessage,
    handleSignupError,
    handleSignupCancellation,
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
