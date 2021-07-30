export const isEnter = e => {
  return e.keyCode === 13;
};

export const isEscape = e => {
  return e.keyCode === 27;
};

export const hasPressedShift = e => {
  return e.shiftKey;
};

export const hasPressedCommandAndForwardslash = e => {
  return e.metaKey && e.keyCode === 191;
};
