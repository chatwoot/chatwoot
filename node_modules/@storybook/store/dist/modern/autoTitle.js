import slash from 'slash';
import dedent from 'ts-dedent';
import { once } from '@storybook/client-logger'; // FIXME: types duplicated type from `core-common', to be
// removed when we remove v6 back-compat.

const stripExtension = path => {
  let parts = [...path];
  const last = parts[parts.length - 1];
  const dotIndex = last.indexOf('.');
  const stripped = dotIndex > 0 ? last.substr(0, dotIndex) : last;
  parts[parts.length - 1] = stripped;
  const [first, ...rest] = parts;

  if (first === '') {
    parts = rest;
  }

  return parts;
};

const indexRe = /^index$/i; // deal with files like "atoms/button/{button,index}.stories.js"

const removeRedundantFilename = paths => {
  let prevVal;
  return paths.filter((val, index) => {
    if (index === paths.length - 1 && (val === prevVal || indexRe.test(val))) {
      return false;
    }

    prevVal = val;
    return true;
  });
};
/**
 * Combines path parts together, without duplicating separators (slashes).  Used instead of `path.join`
 * because this code runs in the browser.
 *
 * @param paths array of paths to join together.
 * @returns joined path string, with single '/' between parts
 */


function pathJoin(paths) {
  const slashes = new RegExp('/{1,}', 'g');
  return paths.join('/').replace(slashes, '/');
}

export const userOrAutoTitleFromSpecifier = (fileName, entry, userTitle) => {
  const {
    directory,
    importPathMatcher,
    titlePrefix = ''
  } = entry || {}; // On Windows, backslashes are used in paths, which can cause problems here
  // slash makes sure we always handle paths with unix-style forward slash

  if (typeof fileName === 'number') {
    once.warn(dedent`
      CSF Auto-title received a numeric fileName. This typically happens when
      webpack is mis-configured in production mode. To force webpack to produce
      filenames, set optimization.moduleIds = "named" in your webpack config.
    `);
  }

  const normalizedFileName = slash(String(fileName));

  if (importPathMatcher.exec(normalizedFileName)) {
    if (!userTitle) {
      const suffix = normalizedFileName.replace(directory, '');
      const titleAndSuffix = slash(pathJoin([titlePrefix, suffix]));
      let path = titleAndSuffix.split('/');
      path = stripExtension(path);
      path = removeRedundantFilename(path);
      return path.join('/');
    }

    if (!titlePrefix) {
      return userTitle;
    }

    return slash(pathJoin([titlePrefix, userTitle]));
  }

  return undefined;
};
export const userOrAutoTitle = (fileName, storiesEntries, userTitle) => {
  for (let i = 0; i < storiesEntries.length; i += 1) {
    const title = userOrAutoTitleFromSpecifier(fileName, storiesEntries[i], userTitle);
    if (title) return title;
  }

  return userTitle || undefined;
};