export const createEvent = eventName => {
  let event;
  if (typeof window.CustomEvent === 'function') {
    event = new CustomEvent(eventName);
  } else {
    event = document.createEvent('CustomEvent');
    event.initCustomEvent(eventName, false, false, null);
  }
  return event;
};

export const dispatchWindowEvent = eventName => {
  const event = createEvent(eventName);
  window.dispatchEvent(event);
};
