export const uIFlags = state => state.uiFlags;
export const itemById = (state, entity) => itemId => {
  if (!state[entity]) return undefined;
  const item = state[entity].byId[itemId];
  return item;
};
