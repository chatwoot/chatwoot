import { useWhatsappAuth } from './useWhatsappAuth';
import { useWhatsappApiRequest } from './useWhatsappApiRequest';
import { useWhatsappSignupFlow } from './useWhatsappSignupFlow';

export function useWhatsappSignupApi({
  authCodeReceived,
  authCode,
  currentStep,
  isProcessing,
  processingMessage,
  store,
  t,
  handleSignupError,
  handleSignupSuccess,
}) {
  const { authHeaders, validateAuthRequirements } = useWhatsappAuth();

  const { createSignupPayload, makeSignupRequest, processApiResponse } =
    useWhatsappApiRequest();

  const { setProcessingState, handleAuthError, handleRequestError } =
    useWhatsappSignupFlow({
      currentStep,
      isProcessing,
      processingMessage,
      t,
    });

  const completeSignupFlow = async businessDataParam => {
    if (!validateAuthRequirements(authCodeReceived, authCode)) {
      handleAuthError(handleSignupError, t);
      return;
    }

    setProcessingState();

    try {
      const payload = createSignupPayload(authCode, store, businessDataParam);
      const response = await makeSignupRequest(payload, authHeaders);
      await processApiResponse(response, authCode, handleSignupSuccess);
    } catch (error) {
      handleRequestError(error, handleSignupError);
    }
  };

  return {
    completeSignupFlow,
  };
}
