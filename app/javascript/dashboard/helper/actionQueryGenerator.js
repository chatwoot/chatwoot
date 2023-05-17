const allElementsString = arr => {
  return arr.every(elem => typeof elem === 'string');
};

const allElementsNumbers = arr => {
  return arr.every(elem => typeof elem === 'number');
};

const formatActionParamsArray = params => {
  if (params.length <= 0) {
    return [];
  }

  if (allElementsString(params) || allElementsNumbers(params)) {
    return [...params];
  }

  return params.map(val => val.id);
};

const formatActionParamsObject = params => {
  if (params.id) {
    return [params.id];
  }

  return [params];
};

const processActionParams = action_params => {
  if (Array.isArray(action_params)) {
    return formatActionParamsArray(action_params);
  }

  if (typeof action_params === 'object') {
    return formatActionParamsObject(action_params);
  }

  if (!action_params) {
    return [];
  }

  return [action_params];
};

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
