Object.defineProperty(exports, '__esModule', { value: true });

/** Flattens a multi-dimensional array */
function flatten(input) {
  const result = [];

  const flattenHelper = (input) => {
    input.forEach((el) => {
      if (Array.isArray(el)) {
        flattenHelper(el );
      } else {
        result.push(el );
      }
    });
  };

  flattenHelper(input);
  return result;
}

exports.flatten = flatten;
//# sourceMappingURL=array.js.map
