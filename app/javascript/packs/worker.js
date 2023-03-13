const methods = {
  async syncStorage({ modelName, data }) {
    return [modelName, data];
  },
};

onmessage = async payload => {
  const { event, params, accountId } = payload.data;

  if (!methods[event]) {
    throw new Error(`Unknown event: ${event}`);
  }

  if (!accountId) {
    throw new Error(`Account ID is not defined`);
  }

  const response = await methods[event](params);
  postMessage({
    event,
    response,
  });
};
