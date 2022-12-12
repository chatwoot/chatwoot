export const str = obj => {
  if (!obj) {
    return '';
  }

  if (typeof obj === 'string') {
    return obj;
  }

  throw new Error(`Description: expected string, got: ${JSON.stringify(obj)}`);
};