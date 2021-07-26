export const isEnter = e => {
  return e.keyCode === 13;
};

export const isEscape = e => {
  return e.keyCode === 27;
};

export const hasPressedShift = e => {
  return e.shiftKey;
};

export const hasPressedShiftAndCKey = e => {
  return e.shiftKey && e.keyCode === 67;
};

export const hasPressedShiftAndVKey = e => {
  return e.shiftKey && e.keyCode === 86;
};

export const hasPressedShiftAndRKey = e => {
  return e.shiftKey && e.keyCode === 82;
};

export const hasPressedShiftAndSKey = e => {
  return e.shiftKey && e.keyCode === 83;
};

export const hasPressedShiftAndBKey = e => {
  return e.shiftKey && e.keyCode === 66;
};

export const hasPressedShiftAndNKey = e => {
  return e.shiftKey && e.keyCode === 78;
};

export const hasPressedShiftAndWKey = e => {
  return e.shiftKey && e.keyCode === 87;
};

export const hasPressedShiftAndAKey = e => {
  return e.shiftKey && e.keyCode === 65;
};

export const hasPressedShiftAndPKey = e => {
  return e.shiftKey && e.keyCode === 80;
};

export const hasPressedShiftAndLKey = e => {
  return e.shiftKey && e.keyCode === 76;
};

export const hasPressedShiftAndEKey = e => {
  return e.shiftKey && e.keyCode === 69;
};

export const hasPressedCommandPlusShiftAndEKey = e => {
  return e.metaKey && e.shiftKey && e.keyCode === 69;
};

export const hasPressedShiftAndOKey = e => {
  return e.shiftKey && e.keyCode === 79;
};

export const hasPressedShiftAndJKey = e => {
  return e.shiftKey && e.keyCode === 74;
};

export const hasPressedShiftAndKKey = e => {
  return e.shiftKey && e.keyCode === 75;
};
