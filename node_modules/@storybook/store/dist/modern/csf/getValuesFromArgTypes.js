import "core-js/modules/es.array.reduce.js";
export const getValuesFromArgTypes = (argTypes = {}) => Object.entries(argTypes).reduce((acc, [arg, {
  defaultValue
}]) => {
  if (typeof defaultValue !== 'undefined') {
    acc[arg] = defaultValue;
  }

  return acc;
}, {});