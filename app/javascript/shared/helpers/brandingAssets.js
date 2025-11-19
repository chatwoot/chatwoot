export const hasCustomBrandAsset = assetPath => {
  if (!assetPath) {
    return false;
  }

  return !assetPath.includes('/brand-assets/');
};

