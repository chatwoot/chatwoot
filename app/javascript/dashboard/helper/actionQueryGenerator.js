const allElementsString = arr => {
  return arr.every(elem => typeof elem === 'string');
};

const allElementsNumbers = arr => {
  return arr.every(elem => typeof elem === 'number');
};

const formatArray = params => {
  if (params.length <= 0) {
    params = [];
  } else if (allElementsString(params) || allElementsNumbers(params)) {
    params = [...params];
  } else {
    params = params.map(val => val.id);
  }
  return params;
};

const generatePayloadForObject = item => {
  if (item.action_params.id) {
    item.action_params = [item.action_params.id];
  } else {
    item.action_params = [item.action_params];
  }
  return item.action_params;
};

const generatePayload = data => {
  const actions = JSON.parse(JSON.stringify(data));
  let payload = actions.map(item => {
    if (Array.isArray(item.action_params)) {
      item.action_params = formatArray(item.action_params);
    } else if (typeof item.action_params === 'object') {
      item.action_params = generatePayloadForObject(item);
    } else if (!item.action_params) {
      item.action_params = [];
    } else {
      item.action_params = [item.action_params];
    }
    return item;
  });
  return payload;
};

export default generatePayload;
