/**
 * Deeply clones an object or array
 * @param  {Mixed} obj The object/array to clone
 * @return {Mixed}     A clone of the initial object or array
 */
function clone(obj) {
  /* eslint guard-for-in: 0*/
  var index,
    length,
    out = obj;

  if (obj !== null && typeof obj === 'object') {
    if (Array.isArray(obj)) {
      out = [];
      for (index = 0, length = obj.length; index < length; index++) {
        out[index] = clone(obj[index]);
      }
    } else {
      out = {};
      for (index in obj) {
        out[index] = clone(obj[index]);
      }
    }
  }
  return out;
}

export default clone;
