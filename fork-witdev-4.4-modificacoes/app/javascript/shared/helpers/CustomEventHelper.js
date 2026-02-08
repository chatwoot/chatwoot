export const createEvent = ({ eventName, data = null }) => {
  let event;
  if (typeof window.CustomEvent === 'function') {
    event = new CustomEvent(eventName, { detail: data });
  } else {
    event = document.createEvent('CustomEvent');
    event.initCustomEvent(eventName, false, false, data);
  }
  return event;
};

export const dispatchWindowEvent = ({ eventName, data }) => {
  const event = createEvent({ eventName, data });
  window.dispatchEvent(event);
};
