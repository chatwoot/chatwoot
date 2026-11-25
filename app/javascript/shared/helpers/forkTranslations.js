/**
 * Shared plumbing for the fazer.ai translation overlays.
 *
 * Upstream's locale trees stay byte-identical to the Chatwoot release we track, so every
 * string the fork owns lives in a sibling `fazer-ai/locale/` tree that is deep merged on
 * top. The dashboard and the survey each have their own bundle and their own upstream
 * tree, so each keeps its own overlay entry point; only the merging lives here.
 *
 * `import.meta.glob` resolves relative to the file that calls it, which is why the caller
 * passes the already-globbed modules in.
 */

const isPlainObject = value =>
  typeof value === 'object' && value !== null && !Array.isArray(value);

export const deepMerge = (target, source) => {
  const result = { ...target };

  Object.entries(source).forEach(([key, value]) => {
    result[key] =
      isPlainObject(value) && isPlainObject(result[key])
        ? deepMerge(result[key], value)
        : value;
  });

  return result;
};

/**
 * Builds the per-locale fork tree from modules globbed as `<base>/<locale>/<file>.json`
 * or `<base>/<locale>.json`, with `localeFromPath` telling the two apart.
 */
export const buildForkMessages = (modules, localeFromPath) => {
  const messages = {};

  // Sorted so `overrides.json` is applied after the file it may collide with, and so the
  // result does not depend on the glob's traversal order.
  Object.keys(modules)
    .sort()
    .forEach(path => {
      const locale = localeFromPath(path);
      const translations = modules[path].default ?? modules[path];
      messages[locale] = deepMerge(messages[locale] ?? {}, translations);
    });

  return messages;
};

/** Deep merges the fork translations on top of upstream's, per locale. */
export const mergeForkMessages = (upstreamMessages, forkMessages) => {
  const merged = { ...upstreamMessages };

  Object.entries(forkMessages).forEach(([locale, translations]) => {
    merged[locale] = deepMerge(merged[locale] ?? {}, translations);
  });

  return merged;
};
