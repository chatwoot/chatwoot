const _excluded = ["globals", "globalTypes"],
      _excluded2 = ["decorators", "loaders", "component", "args", "argTypes"],
      _excluded3 = ["component", "args", "argTypes"];

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

import deprecate from 'util-deprecate';
import dedent from 'ts-dedent';
import global from 'global';
import { logger } from '@storybook/client-logger';
import { toId, sanitize } from '@storybook/csf';
import { combineParameters, normalizeInputTypes } from '@storybook/store';
import { StoryStoreFacade } from './StoryStoreFacade';
// ClientApi (and StoreStore) are really singletons. However they are not created until the
// relevant framework instanciates them via `start.js`. The good news is this happens right away.
let singleton;
const warningAlternatives = {
  addDecorator: `Instead, use \`export const decorators = [];\` in your \`preview.js\`.`,
  addParameters: `Instead, use \`export const parameters = {};\` in your \`preview.js\`.`,
  addLoaders: `Instead, use \`export const loaders = [];\` in your \`preview.js\`.`
};

const warningMessage = method => deprecate(() => {}, dedent`
  \`${method}\` is deprecated, and will be removed in Storybook 7.0.

  ${warningAlternatives[method]}

  Read more at https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-addparameters-and-adddecorator).`);

const warnings = {
  addDecorator: warningMessage('addDecorator'),
  addParameters: warningMessage('addParameters'),
  addLoaders: warningMessage('addLoaders')
};

const checkMethod = (method, deprecationWarning) => {
  var _global$FEATURES;

  if ((_global$FEATURES = global.FEATURES) !== null && _global$FEATURES !== void 0 && _global$FEATURES.storyStoreV7) {
    throw new Error(dedent`You cannot use \`${method}\` with the new Story Store.
      
      ${warningAlternatives[method]}`);
  }

  if (!singleton) {
    throw new Error(`Singleton client API not yet initialized, cannot call \`${method}\`.`);
  }

  if (deprecationWarning) {
    warnings[method]();
  }
};

export const addDecorator = (decorator, deprecationWarning = true) => {
  checkMethod('addDecorator', deprecationWarning);
  singleton.addDecorator(decorator);
};
export const addParameters = (parameters, deprecationWarning = true) => {
  checkMethod('addParameters', deprecationWarning);
  singleton.addParameters(parameters);
};
export const addLoader = (loader, deprecationWarning = true) => {
  checkMethod('addLoader', deprecationWarning);
  singleton.addLoader(loader);
};
export const addArgs = args => {
  checkMethod('addArgs', false);
  singleton.addArgs(args);
};
export const addArgTypes = argTypes => {
  checkMethod('addArgTypes', false);
  singleton.addArgTypes(argTypes);
};
export const addArgsEnhancer = enhancer => {
  checkMethod('addArgsEnhancer', false);
  singleton.addArgsEnhancer(enhancer);
};
export const addArgTypesEnhancer = enhancer => {
  checkMethod('addArgTypesEnhancer', false);
  singleton.addArgTypesEnhancer(enhancer);
};
export const getGlobalRender = () => {
  checkMethod('getGlobalRender', false);
  return singleton.facade.projectAnnotations.render;
};
export const setGlobalRender = render => {
  checkMethod('setGlobalRender', false);
  singleton.facade.projectAnnotations.render = render;
};
const invalidStoryTypes = new Set(['string', 'number', 'boolean', 'symbol']);
export class ClientApi {
  // If we don't get passed modules so don't know filenames, we can
  // just use numeric indexes
  constructor({
    storyStore
  } = {}) {
    this.facade = void 0;
    this.storyStore = void 0;
    this.addons = void 0;
    this.onImportFnChanged = void 0;
    this.lastFileName = 0;
    this.setAddon = deprecate(addon => {
      this.addons = Object.assign({}, this.addons, addon);
    }, dedent`
      \`setAddon\` is deprecated and will be removed in Storybook 7.0.

      https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-setaddon
    `);

    this.addDecorator = decorator => {
      this.facade.projectAnnotations.decorators.push(decorator);
    };

    this.clearDecorators = deprecate(() => {
      this.facade.projectAnnotations.decorators = [];
    }, dedent`
      \`clearDecorators\` is deprecated and will be removed in Storybook 7.0.

      https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-cleardecorators
    `);

    this.addParameters = _ref => {
      let {
        globals,
        globalTypes
      } = _ref,
          parameters = _objectWithoutPropertiesLoose(_ref, _excluded);

      this.facade.projectAnnotations.parameters = combineParameters(this.facade.projectAnnotations.parameters, parameters);

      if (globals) {
        this.facade.projectAnnotations.globals = Object.assign({}, this.facade.projectAnnotations.globals, globals);
      }

      if (globalTypes) {
        this.facade.projectAnnotations.globalTypes = Object.assign({}, this.facade.projectAnnotations.globalTypes, normalizeInputTypes(globalTypes));
      }
    };

    this.addLoader = loader => {
      this.facade.projectAnnotations.loaders.push(loader);
    };

    this.addArgs = args => {
      this.facade.projectAnnotations.args = Object.assign({}, this.facade.projectAnnotations.args, args);
    };

    this.addArgTypes = argTypes => {
      this.facade.projectAnnotations.argTypes = Object.assign({}, this.facade.projectAnnotations.argTypes, normalizeInputTypes(argTypes));
    };

    this.addArgsEnhancer = enhancer => {
      this.facade.projectAnnotations.argsEnhancers.push(enhancer);
    };

    this.addArgTypesEnhancer = enhancer => {
      this.facade.projectAnnotations.argTypesEnhancers.push(enhancer);
    };

    this.storiesOf = (kind, m) => {
      if (!kind && typeof kind !== 'string') {
        throw new Error('Invalid or missing kind provided for stories, should be a string');
      }

      if (!m) {
        logger.warn(`Missing 'module' parameter for story with a kind of '${kind}'. It will break your HMR`);
      }

      if (m) {
        const proto = Object.getPrototypeOf(m);

        if (proto.exports && proto.exports.default) {
          // FIXME: throw an error in SB6.0
          logger.error(`Illegal mix of CSF default export and storiesOf calls in a single file: ${proto.i}`);
        }
      } // eslint-disable-next-line no-plusplus


      const baseFilename = m && m.id ? `${m.id}` : (this.lastFileName++).toString();
      let fileName = baseFilename;
      let i = 1; // Deal with `storiesOf()` being called twice in the same file.
      // On HMR, `this.csfExports[fileName]` will be reset to `{}`, so an empty object is due
      // to this export, not a second call of `storiesOf()`.

      while (this.facade.csfExports[fileName] && Object.keys(this.facade.csfExports[fileName]).length > 0) {
        i += 1;
        fileName = `${baseFilename}-${i}`;
      }

      if (m && m.hot && m.hot.accept) {
        // This module used storiesOf(), so when it re-runs on HMR, it will reload
        // itself automatically without us needing to look at our imports
        m.hot.accept();
        m.hot.dispose(() => {
          this.facade.clearFilenameExports(fileName); // We need to update the importFn as soon as the module re-evaluates
          // (and calls storiesOf() again, etc). We could call `onImportFnChanged()`
          // at the end of every setStories call (somehow), but then we'd need to
          // debounce it somehow for initial startup. Instead, we'll take advantage of
          // the fact that the evaluation of the module happens immediately in the same tick

          setTimeout(() => {
            var _this$onImportFnChang;

            (_this$onImportFnChang = this.onImportFnChanged) === null || _this$onImportFnChang === void 0 ? void 0 : _this$onImportFnChang.call(this, {
              importFn: this.importFn.bind(this)
            });
          }, 0);
        });
      }

      let hasAdded = false;
      const api = {
        kind: kind.toString(),
        add: () => api,
        addDecorator: () => api,
        addLoader: () => api,
        addParameters: () => api
      }; // apply addons

      Object.keys(this.addons).forEach(name => {
        const addon = this.addons[name];

        api[name] = (...args) => {
          addon.apply(api, args);
          return api;
        };
      });
      const meta = {
        id: sanitize(kind),
        title: kind,
        decorators: [],
        loaders: [],
        parameters: {}
      }; // We map these back to a simple default export, even though we have type guarantees at this point

      this.facade.csfExports[fileName] = {
        default: meta
      };
      let counter = 0;

      api.add = (storyName, storyFn, parameters = {}) => {
        hasAdded = true;

        if (typeof storyName !== 'string') {
          throw new Error(`Invalid or missing storyName provided for a "${kind}" story.`);
        }

        if (!storyFn || Array.isArray(storyFn) || invalidStoryTypes.has(typeof storyFn)) {
          throw new Error(`Cannot load story "${storyName}" in "${kind}" due to invalid format. Storybook expected a function/object but received ${typeof storyFn} instead.`);
        }

        const {
          decorators,
          loaders,
          component,
          args,
          argTypes
        } = parameters,
              storyParameters = _objectWithoutPropertiesLoose(parameters, _excluded2); // eslint-disable-next-line no-underscore-dangle


        const storyId = parameters.__id || toId(kind, storyName);
        const csfExports = this.facade.csfExports[fileName]; // Whack a _ on the front incase it is "default"

        csfExports[`story${counter}`] = {
          name: storyName,
          parameters: Object.assign({
            fileName,
            __id: storyId
          }, storyParameters),
          decorators,
          loaders,
          args,
          argTypes,
          component,
          render: storyFn
        };
        counter += 1;
        this.facade.stories[storyId] = {
          id: storyId,
          title: csfExports.default.title,
          name: storyName,
          importPath: fileName
        };
        return api;
      };

      api.addDecorator = decorator => {
        if (hasAdded) throw new Error(`You cannot add a decorator after the first story for a kind.
Read more here: https://github.com/storybookjs/storybook/blob/master/MIGRATION.md#can-no-longer-add-decoratorsparameters-after-stories`);
        meta.decorators.push(decorator);
        return api;
      };

      api.addLoader = loader => {
        if (hasAdded) throw new Error(`You cannot add a loader after the first story for a kind.`);
        meta.loaders.push(loader);
        return api;
      };

      api.addParameters = _ref2 => {
        let {
          component,
          args,
          argTypes
        } = _ref2,
            parameters = _objectWithoutPropertiesLoose(_ref2, _excluded3);

        if (hasAdded) throw new Error(`You cannot add parameters after the first story for a kind.
Read more here: https://github.com/storybookjs/storybook/blob/master/MIGRATION.md#can-no-longer-add-decoratorsparameters-after-stories`);
        meta.parameters = combineParameters(meta.parameters, parameters);
        if (component) meta.component = component;
        if (args) meta.args = Object.assign({}, meta.args, args);
        if (argTypes) meta.argTypes = Object.assign({}, meta.argTypes, argTypes);
        return api;
      };

      return api;
    };

    this.getStorybook = () => {
      const {
        stories
      } = this.storyStore.storyIndex;
      const kinds = {};
      Object.entries(stories).forEach(([storyId, {
        title,
        name,
        importPath
      }]) => {
        if (!kinds[title]) {
          kinds[title] = {
            kind: title,
            fileName: importPath,
            stories: []
          };
        }

        const {
          storyFn
        } = this.storyStore.fromId(storyId);
        kinds[title].stories.push({
          name,
          render: storyFn
        });
      });
      return Object.values(kinds);
    };

    this.raw = () => {
      return this.storyStore.raw();
    };

    this.facade = new StoryStoreFacade();
    this.addons = {};
    this.storyStore = storyStore;
    singleton = this;
  }

  importFn(path) {
    return this.facade.importFn(path);
  }

  getStoryIndex() {
    if (!this.storyStore) {
      throw new Error('Cannot get story index before setting storyStore');
    }

    return this.facade.getStoryIndex(this.storyStore);
  }

  // @deprecated
  get _storyStore() {
    return this.storyStore;
  }

}