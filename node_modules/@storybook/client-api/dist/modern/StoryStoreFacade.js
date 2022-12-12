const _excluded = ["default", "__namedExportsOrder"];

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

import "core-js/modules/es.array.reduce.js";
import global from 'global';
import dedent from 'ts-dedent';
import { SynchronousPromise } from 'synchronous-promise';
import { toId, isExportStory, storyNameFromExport } from '@storybook/csf';
import { userOrAutoTitle, sortStoriesV6 } from '@storybook/store';
import { logger } from '@storybook/client-logger';
export class StoryStoreFacade {
  constructor() {
    this.projectAnnotations = void 0;
    this.stories = void 0;
    this.csfExports = void 0;
    this.projectAnnotations = {
      loaders: [],
      decorators: [],
      parameters: {},
      argsEnhancers: [],
      argTypesEnhancers: [],
      args: {},
      argTypes: {}
    };
    this.stories = {};
    this.csfExports = {};
  } // This doesn't actually import anything because the client-api loads fully
  // on startup, but this is a shim after all.


  importFn(path) {
    return SynchronousPromise.resolve().then(() => {
      const moduleExports = this.csfExports[path];
      if (!moduleExports) throw new Error(`Unknown path: ${path}`);
      return moduleExports;
    });
  }

  getStoryIndex(store) {
    var _this$projectAnnotati, _this$projectAnnotati2;

    const fileNameOrder = Object.keys(this.csfExports);
    const storySortParameter = (_this$projectAnnotati = this.projectAnnotations.parameters) === null || _this$projectAnnotati === void 0 ? void 0 : (_this$projectAnnotati2 = _this$projectAnnotati.options) === null || _this$projectAnnotati2 === void 0 ? void 0 : _this$projectAnnotati2.storySort;
    const storyEntries = Object.entries(this.stories); // Add the kind parameters and global parameters to each entry

    const sortableV6 = storyEntries.map(([storyId, {
      importPath
    }]) => {
      const exports = this.csfExports[importPath];
      const csfFile = store.processCSFFileWithCache(exports, importPath, exports.default.title);
      return [storyId, store.storyFromCSFFile({
        storyId,
        csfFile
      }), csfFile.meta.parameters, this.projectAnnotations.parameters];
    }); // NOTE: the sortStoriesV6 version returns the v7 data format. confusing but more convenient!

    let sortedV7;

    try {
      sortedV7 = sortStoriesV6(sortableV6, storySortParameter, fileNameOrder);
    } catch (err) {
      if (typeof storySortParameter === 'function') {
        throw new Error(dedent`
          Error sorting stories with sort parameter ${storySortParameter}:

          > ${err.message}
          
          Are you using a V7-style sort function in V6 compatibility mode?
          
          More info: https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#v7-style-story-sort
        `);
      }

      throw err;
    }

    const stories = sortedV7.reduce((acc, s) => {
      // We use the original entry we stored in `this.stories` because it is possible that the CSF file itself
      // exports a `parameters.fileName` which can be different and mess up our `importFn`.
      // In fact, in Storyshots there is a Jest transformer that does exactly that.
      // NOTE: this doesn't actually change the story object, just the index.
      acc[s.id] = this.stories[s.id];
      return acc;
    }, {});
    return {
      v: 3,
      stories
    };
  }

  clearFilenameExports(fileName) {
    if (!this.csfExports[fileName]) {
      return;
    } // Clear this module's stories from the storyList and existing exports


    Object.entries(this.stories).forEach(([id, {
      importPath
    }]) => {
      if (importPath === fileName) {
        delete this.stories[id];
      }
    }); // We keep this as an empty record so we can use it to maintain component order

    this.csfExports[fileName] = {};
  } // NOTE: we could potentially share some of this code with the stories.json generation


  addStoriesFromExports(fileName, fileExports) {
    // if the export haven't changed since last time we added them, this is a no-op
    if (this.csfExports[fileName] === fileExports) {
      return;
    } // OTOH, if they have changed, let's clear them out first


    this.clearFilenameExports(fileName);

    const {
      default: defaultExport,
      __namedExportsOrder
    } = fileExports,
          namedExports = _objectWithoutPropertiesLoose(fileExports, _excluded); // eslint-disable-next-line prefer-const


    let {
      id: componentId,
      title
    } = defaultExport || {};
    const specifiers = (global.STORIES || []).map(specifier => Object.assign({}, specifier, {
      importPathMatcher: new RegExp(specifier.importPathMatcher)
    }));
    title = userOrAutoTitle(fileName, specifiers, title);

    if (!title) {
      logger.info(`Unexpected default export without title in '${fileName}': ${JSON.stringify(fileExports.default)}`);
      return;
    }

    this.csfExports[fileName] = Object.assign({}, fileExports, {
      default: Object.assign({}, defaultExport, {
        title
      })
    });
    let sortedExports = namedExports; // prefer a user/loader provided `__namedExportsOrder` array if supplied
    // we do this as es module exports are always ordered alphabetically
    // see https://github.com/storybookjs/storybook/issues/9136

    if (Array.isArray(__namedExportsOrder)) {
      sortedExports = {};

      __namedExportsOrder.forEach(name => {
        const namedExport = namedExports[name];
        if (namedExport) sortedExports[name] = namedExport;
      });
    }

    Object.entries(sortedExports).filter(([key]) => isExportStory(key, defaultExport)).forEach(([key, storyExport]) => {
      var _storyExport$paramete, _storyExport$story;

      const exportName = storyNameFromExport(key);
      const id = ((_storyExport$paramete = storyExport.parameters) === null || _storyExport$paramete === void 0 ? void 0 : _storyExport$paramete.__id) || toId(componentId || title, exportName);
      const name = typeof storyExport !== 'function' && storyExport.name || storyExport.storyName || ((_storyExport$story = storyExport.story) === null || _storyExport$story === void 0 ? void 0 : _storyExport$story.name) || exportName;
      this.stories[id] = {
        id,
        name,
        title,
        importPath: fileName
      };
    });
  }

}