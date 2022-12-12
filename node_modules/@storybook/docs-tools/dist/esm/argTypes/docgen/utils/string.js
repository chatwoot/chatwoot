export var str = function str(obj) {
  if (!obj) {
    return '';
  }

  if (typeof obj === 'string') {
    return obj;
  }

  throw new Error("Description: expected string, got: ".concat(JSON.stringify(obj)));
};