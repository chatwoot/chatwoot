import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.symbol.iterator.js";
import "core-js/modules/es.array.from.js";
import "core-js/modules/es.regexp.exec.js";

var _templateObject;

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

import "regenerator-runtime/runtime.js";

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

function _toConsumableArray(arr) { return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread(); }

function _nonIterableSpread() { throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _iterableToArray(iter) { if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null) return Array.from(iter); }

function _arrayWithoutHoles(arr) { if (Array.isArray(arr)) return _arrayLikeToArray(arr); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

import "core-js/modules/es.function.name.js";
import "core-js/modules/es.array.concat.js";
import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.object.keys.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.promise.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/es.array.map.js";
import "core-js/modules/es.object.entries.js";
import "core-js/modules/es.object.freeze.js";

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

import dedent from 'ts-dedent';
import deprecate from 'util-deprecate';
import global from 'global';
import { includeConditionalArg } from '@storybook/csf';
import { combineParameters } from '../parameters';
import { applyHooks } from '../hooks';
import { defaultDecorateStory } from '../decorators';
import { groupArgsByTarget, NO_TARGET_NAME } from '../args';
import { getValuesFromArgTypes } from './getValuesFromArgTypes';
var argTypeDefaultValueWarning = deprecate(function () {}, dedent(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n  `argType.defaultValue` is deprecated and will be removed in Storybook 7.0.\n\n  https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#no-longer-inferring-default-values-of-args"], ["\n  \\`argType.defaultValue\\` is deprecated and will be removed in Storybook 7.0.\n\n  https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#no-longer-inferring-default-values-of-args"])))); // Combine all the metadata about a story (both direct and inherited from the component/global scope)
// into a "renderable" story function, with all decorators applied, parameters passed as context etc
//
// Note that this story function is *stateless* in the sense that it does not track args or globals
// Instead, it is expected these are tracked separately (if necessary) and are passed into each invocation.

export function prepareStory(storyAnnotations, componentAnnotations, projectAnnotations) {
  var _global$FEATURES;

  // NOTE: in the current implementation we are doing everything once, up front, rather than doing
  // anything at render time. The assumption is that as we don't load all the stories at once, this
  // will have a limited cost. If this proves misguided, we can refactor it.
  var id = storyAnnotations.id,
      name = storyAnnotations.name;
  var title = componentAnnotations.title;
  var parameters = combineParameters(projectAnnotations.parameters, componentAnnotations.parameters, storyAnnotations.parameters);
  var decorators = [].concat(_toConsumableArray(storyAnnotations.decorators || []), _toConsumableArray(componentAnnotations.decorators || []), _toConsumableArray(projectAnnotations.decorators || [])); // Currently it is only possible to set these globally

  var _projectAnnotations$a = projectAnnotations.applyDecorators,
      applyDecorators = _projectAnnotations$a === void 0 ? defaultDecorateStory : _projectAnnotations$a,
      _projectAnnotations$a2 = projectAnnotations.argTypesEnhancers,
      argTypesEnhancers = _projectAnnotations$a2 === void 0 ? [] : _projectAnnotations$a2,
      _projectAnnotations$a3 = projectAnnotations.argsEnhancers,
      argsEnhancers = _projectAnnotations$a3 === void 0 ? [] : _projectAnnotations$a3;
  var loaders = [].concat(_toConsumableArray(projectAnnotations.loaders || []), _toConsumableArray(componentAnnotations.loaders || []), _toConsumableArray(storyAnnotations.loaders || [])); // The render function on annotations *has* to be an `ArgsStoryFn`, so when we normalize
  // CSFv1/2, we use a new field called `userStoryFn` so we know that it can be a LegacyStoryFn

  var render = storyAnnotations.userStoryFn || storyAnnotations.render || componentAnnotations.render || projectAnnotations.render;
  var passedArgTypes = combineParameters(projectAnnotations.argTypes, componentAnnotations.argTypes, storyAnnotations.argTypes);
  var _parameters$passArgsF = parameters.passArgsFirst,
      passArgsFirst = _parameters$passArgsF === void 0 ? true : _parameters$passArgsF; // eslint-disable-next-line no-underscore-dangle

  parameters.__isArgsStory = passArgsFirst && render.length > 0; // Pull out args[X] into initialArgs for argTypes enhancers

  var passedArgs = Object.assign({}, projectAnnotations.args, componentAnnotations.args, storyAnnotations.args);
  var contextForEnhancers = {
    componentId: componentAnnotations.id,
    title: title,
    kind: title,
    // Back compat
    id: id,
    name: name,
    story: name,
    // Back compat
    component: componentAnnotations.component,
    subcomponents: componentAnnotations.subcomponents,
    parameters: parameters,
    initialArgs: passedArgs,
    argTypes: passedArgTypes
  };
  contextForEnhancers.argTypes = argTypesEnhancers.reduce(function (accumulatedArgTypes, enhancer) {
    return enhancer(Object.assign({}, contextForEnhancers, {
      argTypes: accumulatedArgTypes
    }));
  }, contextForEnhancers.argTypes); // Add argTypes[X].defaultValue to initial args (note this deprecated)
  // We need to do this *after* the argTypesEnhancers as they may add defaultValues

  var defaultArgs = getValuesFromArgTypes(contextForEnhancers.argTypes);

  if (Object.keys(defaultArgs).length > 0) {
    argTypeDefaultValueWarning();
  }

  var initialArgsBeforeEnhancers = Object.assign({}, defaultArgs, passedArgs);
  contextForEnhancers.initialArgs = argsEnhancers.reduce(function (accumulatedArgs, enhancer) {
    return Object.assign({}, accumulatedArgs, enhancer(Object.assign({}, contextForEnhancers, {
      initialArgs: accumulatedArgs
    })));
  }, initialArgsBeforeEnhancers); // Add some of our metadata into parameters as we used to do this in 6.x and users may be relying on it

  if (!((_global$FEATURES = global.FEATURES) !== null && _global$FEATURES !== void 0 && _global$FEATURES.breakingChangesV7)) {
    contextForEnhancers.parameters = Object.assign({}, contextForEnhancers.parameters, {
      __id: id,
      globals: projectAnnotations.globals,
      globalTypes: projectAnnotations.globalTypes,
      args: contextForEnhancers.initialArgs,
      argTypes: contextForEnhancers.argTypes
    });
  }

  var applyLoaders = /*#__PURE__*/function () {
    var _ref = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee(context) {
      var loadResults, loaded;
      return regeneratorRuntime.wrap(function _callee$(_context) {
        while (1) {
          switch (_context.prev = _context.next) {
            case 0:
              _context.next = 2;
              return Promise.all(loaders.map(function (loader) {
                return loader(context);
              }));

            case 2:
              loadResults = _context.sent;
              loaded = Object.assign.apply(Object, [{}].concat(_toConsumableArray(loadResults)));
              return _context.abrupt("return", Object.assign({}, context, {
                loaded: loaded
              }));

            case 5:
            case "end":
              return _context.stop();
          }
        }
      }, _callee);
    }));

    return function applyLoaders(_x) {
      return _ref.apply(this, arguments);
    };
  }();

  var undecoratedStoryFn = function undecoratedStoryFn(context) {
    var mappedArgs = Object.entries(context.args).reduce(function (acc, _ref2) {
      var _context$argTypes$key;

      var _ref3 = _slicedToArray(_ref2, 2),
          key = _ref3[0],
          val = _ref3[1];

      var mapping = (_context$argTypes$key = context.argTypes[key]) === null || _context$argTypes$key === void 0 ? void 0 : _context$argTypes$key.mapping;
      acc[key] = mapping && val in mapping ? mapping[val] : val;
      return acc;
    }, {});
    var includedArgs = Object.entries(mappedArgs).reduce(function (acc, _ref4) {
      var _ref5 = _slicedToArray(_ref4, 2),
          key = _ref5[0],
          val = _ref5[1];

      var argType = context.argTypes[key] || {};
      if (includeConditionalArg(argType, mappedArgs, context.globals)) acc[key] = val;
      return acc;
    }, {});
    var includedContext = Object.assign({}, context, {
      args: includedArgs
    });
    var _context$parameters$p = context.parameters.passArgsFirst,
        renderTimePassArgsFirst = _context$parameters$p === void 0 ? true : _context$parameters$p;
    return renderTimePassArgsFirst ? render(includedContext.args, includedContext) : render(includedContext);
  };

  var decoratedStoryFn = applyHooks(applyDecorators)(undecoratedStoryFn, decorators);

  var unboundStoryFn = function unboundStoryFn(context) {
    var _global$FEATURES2;

    var finalContext = context;

    if ((_global$FEATURES2 = global.FEATURES) !== null && _global$FEATURES2 !== void 0 && _global$FEATURES2.argTypeTargetsV7) {
      var argsByTarget = groupArgsByTarget(Object.assign({
        args: context.args
      }, context));
      finalContext = Object.assign({}, context, {
        allArgs: context.args,
        argsByTarget: argsByTarget,
        args: argsByTarget[NO_TARGET_NAME] || {}
      });
    }

    return decoratedStoryFn(finalContext);
  };

  var playFunction = storyAnnotations.play;
  return Object.freeze(Object.assign({}, contextForEnhancers, {
    originalStoryFn: render,
    undecoratedStoryFn: undecoratedStoryFn,
    unboundStoryFn: unboundStoryFn,
    applyLoaders: applyLoaders,
    playFunction: playFunction
  }));
}