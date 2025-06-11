import { ref } from 'vue';

export function useWhatsappSignupState() {
  const fbSdkLoaded = ref(false);
  const isProcessing = ref(false);
  const processingMessage = ref('');
  const authCodeReceived = ref(false);
  const currentStep = ref('initial');
  const authCode = ref(null);
  const businessData = ref(null);
  const isAuthenticating = ref(false);
  const hasSignupStarted = ref(false);

  const resetState = () => {
    currentStep.value = 'initial';
    isProcessing.value = false;
    authCodeReceived.value = false;
    isAuthenticating.value = false;
    hasSignupStarted.value = false;
  };

  return {
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
  };
}
