export default (name, loader) => {
  return async registerLanguage => {
    const module = await loader();
    registerLanguage(name, module.default || module);
  };
};
