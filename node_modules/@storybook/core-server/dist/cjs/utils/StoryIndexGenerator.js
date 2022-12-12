"use strict";

require("core-js/modules/es.symbol.description.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.StoryIndexGenerator = void 0;

require("core-js/modules/es.promise.js");

require("core-js/modules/es.array.sort.js");

require("core-js/modules/es.array.flat.js");

require("core-js/modules/es.array.unscopables.flat.js");

require("core-js/modules/es.array.flat-map.js");

require("core-js/modules/es.array.unscopables.flat-map.js");

var _path = _interopRequireDefault(require("path"));

var _fsExtra = _interopRequireDefault(require("fs-extra"));

var _globby = _interopRequireDefault(require("globby"));

var _slash = _interopRequireDefault(require("slash"));

var _store = require("@storybook/store");

var _coreCommon = require("@storybook/core-common");

var _nodeLogger = require("@storybook/node-logger");

var _csfTools = require("@storybook/csf-tools");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

class StoryIndexGenerator {
  // An internal cache mapping specifiers to a set of path=><set of stories>
  // Later, we'll combine each of these subsets together to form the full index
  // Cache the last value of `getStoryIndex`. We invalidate (by unsetting) when:
  //  - any file changes, including deletions
  //  - the preview changes [not yet implemented]
  constructor(specifiers, options) {
    this.specifiers = specifiers;
    this.options = options;
    this.storyIndexEntries = void 0;
    this.lastIndex = void 0;
    this.storyIndexEntries = new Map();
  }

  async initialize() {
    var _this = this;

    // Find all matching paths for each specifier
    await Promise.all(this.specifiers.map(async function (specifier) {
      var pathToSubIndex = {};
      var fullGlob = (0, _slash.default)(_path.default.join(_this.options.workingDir, specifier.directory, specifier.files));
      var files = await (0, _globby.default)(fullGlob);
      files.sort().forEach(function (absolutePath) {
        var ext = _path.default.extname(absolutePath);

        var relativePath = _path.default.relative(_this.options.workingDir, absolutePath);

        if (!['.js', '.jsx', '.ts', '.tsx', '.mdx'].includes(ext)) {
          _nodeLogger.logger.info(`Skipping ${ext} file ${relativePath}`);

          return;
        }

        pathToSubIndex[absolutePath] = false;
      });

      _this.storyIndexEntries.set(specifier, pathToSubIndex);
    })); // Extract stories for each file

    await this.ensureExtracted();
  }

  async ensureExtracted() {
    var _this2 = this;

    return (await Promise.all(this.specifiers.map(async function (specifier) {
      var entry = _this2.storyIndexEntries.get(specifier);

      return Promise.all(Object.keys(entry).map(async function (absolutePath) {
        return entry[absolutePath] || _this2.extractStories(specifier, absolutePath);
      }));
    }))).flat();
  }

  async extractStories(specifier, absolutePath) {
    var relativePath = _path.default.relative(this.options.workingDir, absolutePath);

    var fileStories = {};
    var entry = this.storyIndexEntries.get(specifier);

    try {
      var importPath = (0, _slash.default)((0, _coreCommon.normalizeStoryPath)(relativePath));

      var makeTitle = function (userTitle) {
        return (0, _store.userOrAutoTitleFromSpecifier)(importPath, specifier, userTitle);
      };

      var csf = (await (0, _csfTools.readCsfOrMdx)(absolutePath, {
        makeTitle: makeTitle
      })).parse();
      csf.stories.forEach(function ({
        id: id,
        name: name
      }) {
        fileStories[id] = {
          id: id,
          title: csf.meta.title,
          name: name,
          importPath: importPath
        };
      });
    } catch (err) {
      if (err.name === 'NoMetaError') {
        _nodeLogger.logger.info(`💡 Skipping ${relativePath}: ${err}`);
      } else {
        _nodeLogger.logger.warn(`🚨 Extraction error on ${relativePath}: ${err}`);

        throw err;
      }
    }

    entry[absolutePath] = fileStories;
    return fileStories;
  }

  async sortStories(storiesList) {
    var stories = {};
    storiesList.forEach(function (subStories) {
      Object.assign(stories, subStories);
    });
    var sortableStories = Object.values(stories); // Skip sorting if we're in v6 mode because we don't have
    // all the info we need here

    if (this.options.storyStoreV7) {
      var storySortParameter = await this.getStorySortParameter();
      var fileNameOrder = this.storyFileNames();
      (0, _store.sortStoriesV7)(sortableStories, storySortParameter, fileNameOrder);
    }

    return sortableStories.reduce(function (acc, item) {
      acc[item.id] = item;
      return acc;
    }, {});
  }

  async getIndex() {
    if (this.lastIndex) return this.lastIndex; // Extract any entries that are currently missing
    // Pull out each file's stories into a list of stories, to be composed and sorted

    var storiesList = await this.ensureExtracted();
    var sorted = await this.sortStories(storiesList);
    var compat = sorted;

    if (this.options.storiesV2Compatibility) {
      var titleToStoryCount = Object.values(sorted).reduce(function (acc, story) {
        acc[story.title] = (acc[story.title] || 0) + 1;
        return acc;
      }, {});
      compat = Object.entries(sorted).reduce(function (acc, entry) {
        var _entry = _slicedToArray(entry, 2),
            id = _entry[0],
            story = _entry[1];

        acc[id] = _objectSpread(_objectSpread({}, story), {}, {
          id: id,
          kind: story.title,
          story: story.name,
          parameters: {
            __id: story.id,
            docsOnly: titleToStoryCount[story.title] === 1 && story.name === 'Page',
            fileName: story.importPath
          }
        });
        return acc;
      }, {});
    }

    this.lastIndex = {
      v: 3,
      stories: compat
    };
    return this.lastIndex;
  }

  invalidate(specifier, importPath, removed) {
    var absolutePath = (0, _slash.default)(_path.default.resolve(this.options.workingDir, importPath));
    var pathToEntries = this.storyIndexEntries.get(specifier);

    if (removed) {
      delete pathToEntries[absolutePath];
    } else {
      pathToEntries[absolutePath] = false;
    }

    this.lastIndex = null;
  }

  async getStorySortParameter() {
    var _this3 = this;

    var previewFile = ['js', 'jsx', 'ts', 'tsx'].map(function (ext) {
      return _path.default.join(_this3.options.configDir, `preview.${ext}`);
    }).find(function (fname) {
      return _fsExtra.default.existsSync(fname);
    });
    var storySortParameter;

    if (previewFile) {
      var previewCode = (await _fsExtra.default.readFile(previewFile, 'utf-8')).toString();
      storySortParameter = await (0, _csfTools.getStorySortParameter)(previewCode);
    }

    return storySortParameter;
  } // Get the story file names in "imported order"


  storyFileNames() {
    return Array.from(this.storyIndexEntries.values()).flatMap(function (r) {
      return Object.keys(r);
    });
  }

}

exports.StoryIndexGenerator = StoryIndexGenerator;