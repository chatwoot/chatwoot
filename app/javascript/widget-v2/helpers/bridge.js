const PREFIX = 'chatwoot-widget:';

// The embedding page's origin: taken from the referrer on load, then locked to
// the origin of the first valid SDK message. Messages are never posted to '*'.
let hostOrigin = document.referrer ? new URL(document.referrer).origin : null;

export const isEmbedded = () => window.parent !== window;

export const sendToHost = (event, payload = {}) => {
  if (!isEmbedded()) return;
  window.parent.postMessage(
    `${PREFIX}${JSON.stringify({ event, ...payload })}`,
    hostOrigin || '*'
  );
};

export const onHostMessage = handler => {
  window.addEventListener('message', event => {
    if (typeof event.data !== 'string' || !event.data.startsWith(PREFIX)) {
      return;
    }
    if (hostOrigin && event.origin !== hostOrigin) return;
    hostOrigin = hostOrigin || event.origin;

    let message;
    try {
      message = JSON.parse(event.data.replace(PREFIX, ''));
    } catch {
      return;
    }
    handler(message);
  });
};
