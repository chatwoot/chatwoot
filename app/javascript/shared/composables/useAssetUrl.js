const stripTrailingSlash = s => (s || '').replace(/\/+$/, '');

/**
 * Returns a function that prefixes asset paths with ASSET_CDN_HOST when set.
 * Reads window.globalConfig.ASSET_CDN_HOST (uppercase, as serialized by Rails).
 * Pass-through for already-absolute URLs (http://, https://, //).
 */
export function useAssetUrl() {
  const cdn = stripTrailingSlash(window.globalConfig?.ASSET_CDN_HOST);
  return path => {
    if (!path) return path;
    if (/^(?:https?:)?\/\//.test(path)) return path;
    if (!cdn) return path;
    return `${cdn}${path}`;
  };
}
