import { useWhatsappSignupValidation } from './useWhatsappSignupValidation';
import { useWhatsappSignupState } from './useWhatsappSignupState';
import { useWhatsappSignupHandlers } from './useWhatsappSignupHandlers';
import { useWhatsappSignupApi } from './useWhatsappSignupApi';
import { useWhatsappFacebookSDK } from './useWhatsappFacebookSDK';
import { useWhatsappMessageHandler } from './useWhatsappMessageHandler';

export function useWhatsappComposableOrchestrator({ store, router, t }) {
  // Validation composable
  const { isValidBusinessData, normalizeBusinessData } =
    useWhatsappSignupValidation();

  // State composable
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

  // Handlers composable
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

  // API composable
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

  // Facebook SDK composable
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

  // Message handler composable
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

    // Methods
    loadFacebookSdk,
    launchEmbeddedSignup,
    handleSignupMessage,
  };
}
