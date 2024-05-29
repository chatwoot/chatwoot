export function getHelpUrlForFeature(featureName) {
  const { helpUrls } = window.chatwootConfig;
  return helpUrls[featureName];
}
