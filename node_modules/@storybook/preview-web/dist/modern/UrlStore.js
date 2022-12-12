const _excluded = ["path", "selectedKind", "selectedStory"];

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

import global from 'global';
import qs from 'qs';
import deprecate from 'util-deprecate';
import { parseArgsParam } from './parseArgsParam';
const {
  history,
  document
} = global;
export function pathToId(path) {
  const match = (path || '').match(/^\/story\/(.+)/);

  if (!match) {
    throw new Error(`Invalid path '${path}',  must start with '/story/'`);
  }

  return match[1];
}

const getQueryString = ({
  selection,
  extraParams
}) => {
  const {
    search = ''
  } = document.location;

  const _qs$parse = qs.parse(search, {
    ignoreQueryPrefix: true
  }),
        rest = _objectWithoutPropertiesLoose(_qs$parse, _excluded);

  return qs.stringify(Object.assign({}, rest, extraParams, selection && {
    id: selection.storyId,
    viewMode: selection.viewMode
  }), {
    encode: false,
    addQueryPrefix: true
  });
};

export const setPath = selection => {
  if (!selection) return;
  const query = getQueryString({
    selection
  });
  const {
    hash = ''
  } = document.location;
  document.title = selection.storyId;
  history.replaceState({}, '', `${document.location.pathname}${query}${hash}`);
};

const isObject = val => val != null && typeof val === 'object' && Array.isArray(val) === false;

const getFirstString = v => {
  if (typeof v === 'string') {
    return v;
  }

  if (Array.isArray(v)) {
    return getFirstString(v[0]);
  }

  if (isObject(v)) {
    // @ts-ignore
    return getFirstString(Object.values(v));
  }

  return undefined;
};

const deprecatedLegacyQuery = deprecate(() => 0, `URL formats with \`selectedKind\` and \`selectedName\` query parameters are deprecated.
Use \`id=$storyId\` instead.
See https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#new-url-structure`);
export const getSelectionSpecifierFromPath = () => {
  const query = qs.parse(document.location.search, {
    ignoreQueryPrefix: true
  });
  const args = typeof query.args === 'string' ? parseArgsParam(query.args) : undefined;
  const globals = typeof query.globals === 'string' ? parseArgsParam(query.globals) : undefined;
  let viewMode = getFirstString(query.viewMode);

  if (typeof viewMode !== 'string' || !viewMode.match(/docs|story/)) {
    viewMode = 'story';
  }

  const path = getFirstString(query.path);
  const storyId = path ? pathToId(path) : getFirstString(query.id);

  if (storyId) {
    return {
      storySpecifier: storyId,
      args,
      globals,
      viewMode
    };
  } // Legacy URL format


  const title = getFirstString(query.selectedKind);
  const name = getFirstString(query.selectedStory);

  if (title && name) {
    deprecatedLegacyQuery();
    return {
      storySpecifier: {
        title,
        name
      },
      args,
      globals,
      viewMode
    };
  }

  return null;
};
export class UrlStore {
  constructor() {
    this.selectionSpecifier = void 0;
    this.selection = void 0;
    this.selectionSpecifier = getSelectionSpecifierFromPath();
  }

  setSelection(selection) {
    this.selection = selection;
    setPath(this.selection);
  }

  setQueryParams(queryParams) {
    const query = getQueryString({
      extraParams: queryParams
    });
    const {
      hash = ''
    } = document.location;
    history.replaceState({}, '', `${document.location.pathname}${query}${hash}`);
  }

}