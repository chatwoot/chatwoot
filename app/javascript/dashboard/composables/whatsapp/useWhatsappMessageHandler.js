import { useWhatsappMessageValidation } from './useWhatsappMessageValidation';
import { useWhatsappEventProcessors } from './useWhatsappEventProcessors';

export function useWhatsappMessageHandler({
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
}) {
  const { validateMessageOrigin, parseMessageData, isWhatsappSignupMessage } =
    useWhatsappMessageValidation();

  const { processFinishEvent, processErrorEvent, processCancelEvent } =
    useWhatsappEventProcessors({
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

  const eventProcessorMap = {
    FINISH: processFinishEvent,
    CANCEL: processCancelEvent,
    error: processErrorEvent,
  };

  const handleEmbeddedSignupData = async data => {
    const processor = eventProcessorMap[data.event];
    if (processor) {
      await processor(data);
    }
  };

  const handleSignupMessage = event => {
    if (!validateMessageOrigin(event.origin)) return;

    const data = parseMessageData(event.data);
    if (isWhatsappSignupMessage(data)) {
      handleEmbeddedSignupData(data);
    }
  };

  return {
    handleSignupMessage,
  };
}
