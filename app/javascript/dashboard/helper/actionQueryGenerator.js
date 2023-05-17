/**
 * Formats an array of elements into a string.
 * @param {Array} arr - The array of elements.
 * @returns {boolean} - Returns true if all elements in the array are of type 'string', otherwise returns false.
 */
const allElementsString = arr => {
  return arr.every(elem => typeof elem === 'string');
};

/**
 * Checks if all elements in an array are of type 'number'.
 * @param {Array} arr - The array of elements.
 * @returns {boolean} - Returns true if all elements in the array are of type 'number', otherwise returns false.
 */
const allElementsNumbers = arr => {
  return arr.every(elem => typeof elem === 'number');
};

/**
 * Formats an array of action parameters.
 * @param {Array} params - The array of action parameters.
 * @returns {Array} - Returns the formatted array of action parameters.
 */
const formatActionParamsArray = params => {
  if (params.length === 0) {
    return [];
  }

  if (allElementsString(params) || allElementsNumbers(params)) {
    return [...params];
  }

  return params.map(val => val.id);
};

/**
 * Formats an object of action parameters.
 * @param {Object} params - The object of action parameters.
 * @returns {Array} - Returns the formatted array of action parameters.
 */
const formatActionParamsObject = params => {
  if (params?.value !== undefined) {
    return [params.value];
  }

  if (params?.id) {
    return [params.id];
  }

  return [params];
};

/**
 * Processes the action parameters and returns them in a formatted array.
 * @param {Array|Object} action_params - The action parameters to be processed.
 * @returns {Array} - Returns the processed and formatted array of action parameters.
 */
const processActionParams = action_params => {
  if (!action_params) {
    return [];
  }

  if (Array.isArray(action_params)) {
    return formatActionParamsArray(action_params);
  }

  if (typeof action_params === 'object') {
    return formatActionParamsObject(action_params);
  }

  return [action_params];
};

/**
 * Generates the payload by processing the data and formatting the action parameters.
 * @param {Array} data - The data containing actions and their parameters.
 * @returns {Array} - Returns the generated payload with processed action parameters.
 */
const generatePayload = data => {
  const actions = JSON.parse(JSON.stringify(data));

  return actions.map(item => {
    const { action_params } = item;
    return {
      ...item,
      action_params: processActionParams(action_params),
    };
  });
};

export default generatePayload;
