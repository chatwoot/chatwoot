import resolveFrom from 'resolve-from';
export var safeResolveFrom = function (path, file) {
  try {
    return resolveFrom(path, file);
  } catch (e) {
    return undefined;
  }
};
export var safeResolve = function (file) {
  try {
    return require.resolve(file);
  } catch (e) {
    return undefined;
  }
};