// `addons/x` is for the monorepo, `addon-x` is for normal usage
const packageRe = /(addons\/|addon-)(docs|controls)/;
export const hasDocsOrControls = options => {
  var _options$presetsList;

  return (_options$presetsList = options.presetsList) === null || _options$presetsList === void 0 ? void 0 : _options$presetsList.some(preset => packageRe.test(preset.name));
};