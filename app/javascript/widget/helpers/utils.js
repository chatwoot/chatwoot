/* eslint-disable import/prefer-default-export */
export const isEmptyObject = obj =>
  Object.keys(obj).length === 0 && obj.constructor === Object;

export const arrayToHashById = array =>
  array.reduce((map, obj) => {
    const newMap = map;
    newMap[obj.id] = obj;
    return newMap;
  }, {});

export const IFrameHelper = {
  isIFrame: () => window.self !== window.top,
  sendMessage: msg => {
    window.parent.postMessage(
      `chatwoot-widget:${JSON.stringify({ ...msg })}`,
      '*'
    );
  },
};

export const getAvailableAgentsText = (agents = []) => {
  const count = agents.length;
  if (count === 1) {
    const [agent] = agents;
    return `${agent.name} is available`;
  }

  if (count === 2) {
    const [first, second] = agents;
    return `${first.name} and ${second.name} is available`;
  }

  const [agent] = agents;
  const rest = agents.length - 1;
  return `${agent.name} and ${rest} others are available`;
};
