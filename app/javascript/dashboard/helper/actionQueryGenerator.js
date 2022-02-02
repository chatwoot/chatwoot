const generatePayload = data => {
  let payload = data.map(item => {
    if (Array.isArray(item.action_params)) {
      item.action_params = item.action_params.map(val => val.id);
    } else if (typeof item.values === 'object') {
      item.action_params = [item.action_params.id];
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
