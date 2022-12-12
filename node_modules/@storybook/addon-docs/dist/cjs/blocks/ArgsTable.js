"use strict";

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.symbol.iterator.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.array.from.js");

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.weak-map.js");

require("core-js/modules/es.object.get-own-property-descriptor.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getComponent = exports.extractComponentArgTypes = exports.StoryTable = exports.ComponentsTable = exports.ArgsTable = void 0;

require("core-js/modules/es.array.includes.js");

require("core-js/modules/es.string.includes.js");

require("core-js/modules/es.object.assign.js");

require("core-js/modules/es.array.sort.js");

require("core-js/modules/es.array.find.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.object.values.js");

var _react = _interopRequireWildcard(require("react"));

var _mapValues = _interopRequireDefault(require("lodash/mapValues"));

var _components = require("@storybook/components");

var _addons = require("@storybook/addons");

var _store = require("@storybook/store");

var _coreEvents = _interopRequireDefault(require("@storybook/core-events"));

var _DocsContext = require("./DocsContext");

var _types = require("./types");

var _utils = require("./utils");

var _Story = require("./Story");

var _useStory = require("./useStory");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _getRequireWildcardCache(nodeInterop) { if (typeof WeakMap !== "function") return null; var cacheBabelInterop = new WeakMap(); var cacheNodeInterop = new WeakMap(); return (_getRequireWildcardCache = function _getRequireWildcardCache(nodeInterop) { return nodeInterop ? cacheNodeInterop : cacheBabelInterop; })(nodeInterop); }

function _interopRequireWildcard(obj, nodeInterop) { if (!nodeInterop && obj && obj.__esModule) { return obj; } if (obj === null || _typeof(obj) !== "object" && typeof obj !== "function") { return { default: obj }; } var cache = _getRequireWildcardCache(nodeInterop); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (key !== "default" && Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj.default = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

function _extends() { _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; }; return _extends.apply(this, arguments); }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

var getContext = function getContext(storyId, context) {
  var story = context.storyById(storyId);

  if (!story) {
    throw new Error("Unknown story: ".concat(storyId));
  }

  return context.getStoryContext(story);
};

var useArgs = function useArgs(storyId, context) {
  var channel = _addons.addons.getChannel();

  var storyContext = getContext(storyId, context);

  var _useState = (0, _react.useState)(storyContext.args),
      _useState2 = _slicedToArray(_useState, 2),
      args = _useState2[0],
      setArgs = _useState2[1];

  (0, _react.useEffect)(function () {
    var cb = function cb(changed) {
      if (changed.storyId === storyId) {
        setArgs(changed.args);
      }
    };

    channel.on(_coreEvents.default.STORY_ARGS_UPDATED, cb);
    return function () {
      return channel.off(_coreEvents.default.STORY_ARGS_UPDATED, cb);
    };
  }, [storyId]);
  var updateArgs = (0, _react.useCallback)(function (updatedArgs) {
    return channel.emit(_coreEvents.default.UPDATE_STORY_ARGS, {
      storyId: storyId,
      updatedArgs: updatedArgs
    });
  }, [storyId]);
  var resetArgs = (0, _react.useCallback)(function (argNames) {
    return channel.emit(_coreEvents.default.RESET_STORY_ARGS, {
      storyId: storyId,
      argNames: argNames
    });
  }, [storyId]);
  return [args, updateArgs, resetArgs];
};

var useGlobals = function useGlobals(storyId, context) {
  var channel = _addons.addons.getChannel();

  var storyContext = getContext(storyId, context);

  var _useState3 = (0, _react.useState)(storyContext.globals),
      _useState4 = _slicedToArray(_useState3, 2),
      globals = _useState4[0],
      setGlobals = _useState4[1];

  (0, _react.useEffect)(function () {
    var cb = function cb(changed) {
      setGlobals(changed.globals);
    };

    channel.on(_coreEvents.default.GLOBALS_UPDATED, cb);
    return function () {
      return channel.off(_coreEvents.default.GLOBALS_UPDATED, cb);
    };
  }, []);
  return [globals];
};

var extractComponentArgTypes = function extractComponentArgTypes(component, _ref, include, exclude) {
  var id = _ref.id,
      storyById = _ref.storyById;

  var _storyById = storyById(id),
      parameters = _storyById.parameters;

  var _ref2 = parameters.docs || {},
      extractArgTypes = _ref2.extractArgTypes;

  if (!extractArgTypes) {
    throw new Error(_components.ArgsTableError.ARGS_UNSUPPORTED);
  }

  var argTypes = extractArgTypes(component);
  argTypes = (0, _store.filterArgTypes)(argTypes, include, exclude);
  return argTypes;
};

exports.extractComponentArgTypes = extractComponentArgTypes;

var isShortcut = function isShortcut(value) {
  return value && [_types.CURRENT_SELECTION, _types.PRIMARY_STORY].includes(value);
};

var getComponent = function getComponent() {
  var props = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};

  var _ref3 = arguments.length > 1 ? arguments[1] : undefined,
      id = _ref3.id,
      storyById = _ref3.storyById;

  var _ref4 = props,
      of = _ref4.of;
  var _ref5 = props,
      story = _ref5.story;

  var _storyById2 = storyById(id),
      component = _storyById2.component;

  if (isShortcut(of) || isShortcut(story)) {
    return component || null;
  }

  if (!of) {
    throw new Error(_components.ArgsTableError.NO_COMPONENT);
  }

  return of;
};

exports.getComponent = getComponent;

var addComponentTabs = function addComponentTabs(tabs, components, context, include, exclude, sort) {
  return Object.assign({}, tabs, (0, _mapValues.default)(components, function (comp) {
    return {
      rows: extractComponentArgTypes(comp, context, include, exclude),
      sort: sort
    };
  }));
};

var StoryTable = function StoryTable(props) {
  var context = (0, _react.useContext)(_DocsContext.DocsContext);
  var currentId = context.id,
      componentStories = context.componentStories;
  var storyName = props.story,
      component = props.component,
      subcomponents = props.subcomponents,
      showComponent = props.showComponent,
      include = props.include,
      exclude = props.exclude,
      sort = props.sort;

  try {
    var storyId;

    switch (storyName) {
      case _types.CURRENT_SELECTION:
        {
          storyId = currentId;
          break;
        }

      case _types.PRIMARY_STORY:
        {
          var primaryStory = componentStories()[0];
          storyId = primaryStory.id;
          break;
        }

      default:
        {
          storyId = (0, _Story.lookupStoryId)(storyName, context);
        }
    }

    var story = (0, _useStory.useStory)(storyId, context); // eslint-disable-next-line prefer-const

    var _useArgs = useArgs(storyId, context),
        _useArgs2 = _slicedToArray(_useArgs, 3),
        args = _useArgs2[0],
        updateArgs = _useArgs2[1],
        resetArgs = _useArgs2[2];

    var _useGlobals = useGlobals(storyId, context),
        _useGlobals2 = _slicedToArray(_useGlobals, 1),
        globals = _useGlobals2[0];

    if (!story) return /*#__PURE__*/_react.default.createElement(_components.ArgsTable, {
      isLoading: true,
      updateArgs: updateArgs,
      resetArgs: resetArgs
    });
    var argTypes = (0, _store.filterArgTypes)(story.argTypes, include, exclude);
    var mainLabel = (0, _utils.getComponentName)(component) || 'Story';

    var tabs = _defineProperty({}, mainLabel, {
      rows: argTypes,
      args: args,
      globals: globals,
      updateArgs: updateArgs,
      resetArgs: resetArgs
    }); // Use the dynamically generated component tabs if there are no controls


    var storyHasArgsWithControls = argTypes && Object.values(argTypes).find(function (v) {
      return !!(v !== null && v !== void 0 && v.control);
    });

    if (!storyHasArgsWithControls) {
      updateArgs = null;
      resetArgs = null;
      tabs = {};
    }

    if (component && (!storyHasArgsWithControls || showComponent)) {
      tabs = addComponentTabs(tabs, _defineProperty({}, mainLabel, component), context, include, exclude);
    }

    if (subcomponents) {
      if (Array.isArray(subcomponents)) {
        throw new Error("Unexpected subcomponents array. Expected an object whose keys are tab labels and whose values are components.");
      }

      tabs = addComponentTabs(tabs, subcomponents, context, include, exclude);
    }

    return /*#__PURE__*/_react.default.createElement(_components.TabbedArgsTable, {
      tabs: tabs,
      sort: sort
    });
  } catch (err) {
    return /*#__PURE__*/_react.default.createElement(_components.ArgsTable, {
      error: err.message
    });
  }
};

exports.StoryTable = StoryTable;

var ComponentsTable = function ComponentsTable(props) {
  var context = (0, _react.useContext)(_DocsContext.DocsContext);
  var components = props.components,
      include = props.include,
      exclude = props.exclude,
      sort = props.sort;
  var tabs = addComponentTabs({}, components, context, include, exclude);
  return /*#__PURE__*/_react.default.createElement(_components.TabbedArgsTable, {
    tabs: tabs,
    sort: sort
  });
};

exports.ComponentsTable = ComponentsTable;

var ArgsTable = function ArgsTable(props) {
  var context = (0, _react.useContext)(_DocsContext.DocsContext);
  var id = context.id,
      storyById = context.storyById;

  var _storyById3 = storyById(id),
      controls = _storyById3.parameters.controls,
      subcomponents = _storyById3.subcomponents;

  var _ref6 = props,
      include = _ref6.include,
      exclude = _ref6.exclude,
      components = _ref6.components,
      sortProp = _ref6.sort;
  var _ref7 = props,
      storyName = _ref7.story;
  var sort = sortProp || (controls === null || controls === void 0 ? void 0 : controls.sort);
  var main = getComponent(props, context);

  if (storyName) {
    return /*#__PURE__*/_react.default.createElement(StoryTable, _extends({}, props, {
      component: main,
      subcomponents: subcomponents,
      sort: sort
    }));
  }

  if (!components && !subcomponents) {
    var mainProps;

    try {
      mainProps = {
        rows: extractComponentArgTypes(main, context, include, exclude)
      };
    } catch (err) {
      mainProps = {
        error: err.message
      };
    }

    return /*#__PURE__*/_react.default.createElement(_components.ArgsTable, _extends({}, mainProps, {
      sort: sort
    }));
  }

  if (components) {
    return /*#__PURE__*/_react.default.createElement(ComponentsTable, _extends({}, props, {
      components: components,
      sort: sort
    }));
  }

  var mainLabel = (0, _utils.getComponentName)(main);
  return /*#__PURE__*/_react.default.createElement(ComponentsTable, _extends({}, props, {
    components: Object.assign(_defineProperty({}, mainLabel, main), subcomponents),
    sort: sort
  }));
};

exports.ArgsTable = ArgsTable;
ArgsTable.defaultProps = {
  of: _types.CURRENT_SELECTION
};