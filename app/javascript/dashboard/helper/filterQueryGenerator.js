const generatePayload = data => {
  return data.map(item => {
    if (Array.isArray(item.values)) {
      item.values = item.values.map(val => val.id);
    } else if (typeof item.values === 'object') {
      item.values = [item.values.id];
    } else {
      item.values = [item.values];
    }
    return item;
  });
};

export default generatePayload;
