export function useWhatsappLifecycle({ loadFacebookSdk, handleSignupMessage }) {
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
    initialize,
    cleanupMessageListener,
  };
}
