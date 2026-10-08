import helpUrls from '../../../../config/feature_help_urls.yml';

export function getHelpUrlForFeature(featureName) {
  return helpUrls[featureName];
}
