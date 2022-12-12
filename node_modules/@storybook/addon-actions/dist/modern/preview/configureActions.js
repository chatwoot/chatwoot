export const config = {
  depth: 10,
  clearOnStoryChange: true,
  limit: 50
};
export const configureActions = (options = {}) => {
  Object.assign(config, options);
};