const _excluded = ["stories", "v"];

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

function _toPropertyKey(arg) { var key = _toPrimitive(arg, "string"); return typeof key === "symbol" ? key : String(key); }

function _toPrimitive(input, hint) { if (typeof input !== "object" || input === null) return input; var prim = input[Symbol.toPrimitive]; if (prim !== undefined) { var res = prim.call(input, hint || "default"); if (typeof res !== "object") return res; throw new TypeError("@@toPrimitive must return a primitive value."); } return (hint === "string" ? String : Number)(input); }

import "core-js/modules/es.array.reduce.js";
import global from 'global';
import dedent from 'ts-dedent';
import { transformStoriesRawToStoriesHash, transformStoryIndexToStoriesHash } from '../lib/stories';
const {
  location,
  fetch
} = global;
// eslint-disable-next-line no-useless-escape
const findFilename = /(\/((?:[^\/]+?)\.[^\/]+?)|\/)$/;
export const getSourceType = (source, refId) => {
  const {
    origin: localOrigin,
    pathname: localPathname
  } = location;
  const {
    origin: sourceOrigin,
    pathname: sourcePathname
  } = new URL(source);
  const localFull = `${localOrigin + localPathname}`.replace(findFilename, '');
  const sourceFull = `${sourceOrigin + sourcePathname}`.replace(findFilename, '');

  if (localFull === sourceFull) {
    return ['local', sourceFull];
  }

  if (refId || source) {
    return ['external', sourceFull];
  }

  return [null, null];
};
export const defaultStoryMapper = (b, a) => {
  return Object.assign({}, a, {
    kind: a.kind.replace('|', '/')
  });
};

const addRefIds = (input, ref) => {
  return Object.entries(input).reduce((acc, [id, item]) => {
    return Object.assign({}, acc, {
      [id]: Object.assign({}, item, {
        refId: ref.id
      })
    });
  }, {});
};

const handle = async request => {
  if (request) {
    return Promise.resolve(request).then(response => response.ok ? response.json() : {}).catch(error => ({
      error
    }));
  }

  return {};
};

const map = (input, ref, options) => {
  const {
    storyMapper
  } = options;

  if (storyMapper) {
    return Object.entries(input).reduce((acc, [id, item]) => {
      return Object.assign({}, acc, {
        [id]: storyMapper(ref, item)
      });
    }, {});
  }

  return input;
};

export const init = ({
  store,
  provider,
  singleStory
}, {
  runCheck = true
} = {}) => {
  const api = {
    findRef: source => {
      const refs = api.getRefs();
      return Object.values(refs).find(({
        url
      }) => url.match(source));
    },
    changeRefVersion: (id, url) => {
      const {
        versions,
        title
      } = api.getRefs()[id];
      const ref = {
        id,
        url,
        versions,
        title,
        stories: {}
      };
      api.checkRef(ref);
    },
    changeRefState: (id, ready) => {
      const _api$getRefs = api.getRefs(),
            {
        [id]: ref
      } = _api$getRefs,
            updated = _objectWithoutPropertiesLoose(_api$getRefs, [id].map(_toPropertyKey));

      updated[id] = Object.assign({}, ref, {
        ready
      });
      store.setState({
        refs: updated
      });
    },
    checkRef: async ref => {
      const {
        id,
        url,
        version,
        type
      } = ref;
      const isPublic = type === 'server-checked'; // ref's type starts as either 'unknown' or 'server-checked'
      // "server-checked" happens when we were able to verify the storybook is accessible from node (without cookies)
      // "unknown" happens if the request was declined of failed (this can happen because the storybook doesn't exists or authentication is required)
      //
      // we then make a request for stories.json
      //
      // if this request fails when storybook is server-checked we mark the ref as "auto-inject", this is a fallback mechanism for local storybook, legacy storybooks, and storybooks that lack stories.json
      // if the request fails with type "unknown" we give up and show an error
      // if the request succeeds we set the ref to 'lazy' type, and show the stories in the sidebar without injecting the iframe first
      //
      // then we fetch metadata if the above fetch succeeded

      const loadedData = {};
      const query = version ? `?version=${version}` : '';
      const credentials = isPublic ? 'omit' : 'include'; // In theory the `/iframe.html` could be private and the `stories.json` could not exist, but in practice
      // the only private servers we know about (Chromatic) always include `stories.json`. So we can tell
      // if the ref actually exists by simply checking `stories.json` w/ credentials.

      const storiesFetch = await fetch(`${url}/stories.json${query}`, {
        headers: {
          Accept: 'application/json'
        },
        credentials
      });

      if (!storiesFetch.ok && !isPublic) {
        loadedData.error = {
          message: dedent`
            Error: Loading of ref failed
              at fetch (lib/api/src/modules/refs.ts)

            URL: ${url}

            We weren't able to load the above URL,
            it's possible a CORS error happened.

            Please check your dev-tools network tab.
          `
        };
      } else if (storiesFetch.ok) {
        const [stories, metadata] = await Promise.all([handle(storiesFetch), handle(fetch(`${url}/metadata.json${query}`, {
          headers: {
            Accept: 'application/json'
          },
          credentials,
          cache: 'no-cache'
        }).catch(() => false))]);
        Object.assign(loadedData, Object.assign({}, stories, metadata));
      }

      const versions = ref.versions && Object.keys(ref.versions).length ? ref.versions : loadedData.versions;
      await api.setRef(id, Object.assign({
        id,
        url
      }, loadedData, versions ? {
        versions
      } : {}, {
        error: loadedData.error,
        type: !loadedData.stories ? 'auto-inject' : 'lazy'
      }));
    },
    getRefs: () => {
      const {
        refs = {}
      } = store.getState();
      return refs;
    },
    setRef: (id, _ref, ready = false) => {
      let {
        stories,
        v
      } = _ref,
          rest = _objectWithoutPropertiesLoose(_ref, _excluded);

      if (singleStory) return;
      const {
        storyMapper = defaultStoryMapper
      } = provider.getConfig();
      const ref = api.getRefs()[id];
      let storiesHash;

      if (stories) {
        if (v === 2) {
          storiesHash = transformStoriesRawToStoriesHash(map(stories, ref, {
            storyMapper
          }), {
            provider
          });
        } else if (!v) {
          throw new Error('Composition: Missing stories.json version');
        } else {
          const index = stories;
          storiesHash = transformStoryIndexToStoriesHash({
            v,
            stories: index
          }, {
            provider
          });
        }

        storiesHash = addRefIds(storiesHash, ref);
      }

      api.updateRef(id, Object.assign({
        stories: storiesHash
      }, rest, {
        ready
      }));
    },
    updateRef: (id, data) => {
      const _api$getRefs2 = api.getRefs(),
            {
        [id]: ref
      } = _api$getRefs2,
            updated = _objectWithoutPropertiesLoose(_api$getRefs2, [id].map(_toPropertyKey));

      updated[id] = Object.assign({}, ref, data);
      /* eslint-disable no-param-reassign */

      const ordered = Object.keys(initialState).reduce((obj, key) => {
        obj[key] = updated[key];
        return obj;
      }, {});
      /* eslint-enable no-param-reassign */

      store.setState({
        refs: ordered
      });
    }
  };
  const refs = !singleStory && provider.getConfig().refs || {};
  const initialState = refs;

  if (runCheck) {
    Object.entries(refs).forEach(([k, v]) => {
      api.checkRef(v);
    });
  }

  return {
    api,
    state: {
      refs: initialState
    }
  };
};