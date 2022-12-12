import "regenerator-runtime/runtime.js";

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

import "core-js/modules/es.array.concat.js";
import "core-js/modules/es.array.join.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.array.includes.js";
import "core-js/modules/es.string.includes.js";
import "core-js/modules/es.promise.js";
import { pathExists } from 'fs-extra';
import path from 'path';
import { getInterpretedFile, loadManagerOrAddonsFile, serverRequire } from '@storybook/core-common';
import { getAutoRefs } from '../manager-config'; // Addons automatically installed when running `sb init` (see baseGenerator.ts)

export var DEFAULT_ADDONS = ['@storybook/addon-links', '@storybook/addon-essentials']; // Addons we can safely ignore because they don't affect the manager

export var IGNORED_ADDONS = ['@storybook/preset-create-react-app', '@storybook/preset-scss', '@storybook/preset-typescript'].concat(DEFAULT_ADDONS);
export var getPrebuiltDir = /*#__PURE__*/function () {
  var _ref = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee(options) {
    var configDir, smokeTest, managerCache, prebuiltDir, hasPrebuiltManager, hasManagerConfig, mainConfigFile, _serverRequire, addons, refs, managerBabel, managerWebpack, features, autoRefs;

    return regeneratorRuntime.wrap(function _callee$(_context) {
      while (1) {
        switch (_context.prev = _context.next) {
          case 0:
            configDir = options.configDir, smokeTest = options.smokeTest, managerCache = options.managerCache;

            if (!(managerCache === false || smokeTest)) {
              _context.next = 3;
              break;
            }

            return _context.abrupt("return", false);

          case 3:
            prebuiltDir = path.join(__dirname, '../../../prebuilt');
            _context.next = 6;
            return pathExists(path.join(prebuiltDir, 'index.html'));

          case 6:
            hasPrebuiltManager = _context.sent;

            if (hasPrebuiltManager) {
              _context.next = 9;
              break;
            }

            return _context.abrupt("return", false);

          case 9:
            hasManagerConfig = !!loadManagerOrAddonsFile({
              configDir: configDir
            });

            if (!hasManagerConfig) {
              _context.next = 12;
              break;
            }

            return _context.abrupt("return", false);

          case 12:
            mainConfigFile = getInterpretedFile(path.resolve(configDir, 'main'));

            if (mainConfigFile) {
              _context.next = 15;
              break;
            }

            return _context.abrupt("return", false);

          case 15:
            _serverRequire = serverRequire(mainConfigFile), addons = _serverRequire.addons, refs = _serverRequire.refs, managerBabel = _serverRequire.managerBabel, managerWebpack = _serverRequire.managerWebpack, features = _serverRequire.features;

            if (!(!addons || refs || managerBabel || managerWebpack || features)) {
              _context.next = 18;
              break;
            }

            return _context.abrupt("return", false);

          case 18:
            if (!DEFAULT_ADDONS.some(function (addon) {
              return !addons.includes(addon);
            })) {
              _context.next = 20;
              break;
            }

            return _context.abrupt("return", false);

          case 20:
            if (!addons.some(function (addon) {
              return !IGNORED_ADDONS.includes(addon);
            })) {
              _context.next = 22;
              break;
            }

            return _context.abrupt("return", false);

          case 22:
            _context.next = 24;
            return getAutoRefs(options);

          case 24:
            autoRefs = _context.sent;

            if (!(autoRefs.length > 0)) {
              _context.next = 27;
              break;
            }

            return _context.abrupt("return", false);

          case 27:
            return _context.abrupt("return", prebuiltDir);

          case 28:
          case "end":
            return _context.stop();
        }
      }
    }, _callee);
  }));

  return function getPrebuiltDir(_x) {
    return _ref.apply(this, arguments);
  };
}();