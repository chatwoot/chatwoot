export function useWhatsappMessageValidation() {
  const validateMessageOrigin = origin => {
    try {
      const originUrl = new URL(origin);
      const allowedHosts = ['facebook.com', 'www.facebook.com'];
      return allowedHosts.includes(originUrl.hostname);
    } catch (error) {
      return false;
    }
  };

  const parseMessageData = data => {
    try {
      return JSON.parse(data);
    } catch (error) {
      return null;
    }
  };

  const isWhatsappSignupMessage = data => {
    return data?.type === 'WA_EMBEDDED_SIGNUP';
  };

  return {
    validateMessageOrigin,
    parseMessageData,
    isWhatsappSignupMessage,
  };
}
