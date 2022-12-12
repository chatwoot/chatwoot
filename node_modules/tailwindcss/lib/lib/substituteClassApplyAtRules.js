"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = _default;

var _lodash = _interopRequireDefault(require("lodash"));

var _postcss = _interopRequireDefault(require("postcss"));

var _escapeClassName = _interopRequireDefault(require("../util/escapeClassName"));

var _prefixSelector = _interopRequireDefault(require("../util/prefixSelector"));

var _increaseSpecificity = _interopRequireDefault(require("../util/increaseSpecificity"));

var _featureFlags = require("../featureFlags");

var _applyComplexClasses = _interopRequireDefault(require("../flagged/applyComplexClasses"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function buildClassTable(css) {
  const classTable = {};
  css.walkRules(rule => {
    if (!_lodash.default.has(classTable, rule.selector)) {
      classTable[rule.selector] = [];
    }

    classTable[rule.selector].push(rule);
  });
  return classTable;
}

function buildShadowTable(generatedUtilities) {
  const utilities = _postcss.default.root();

  _postcss.default.root({
    nodes: generatedUtilities
  }).walkAtRules('variants', atRule => {
    utilities.append(atRule.clone().nodes);
  });

  return buildClassTable(utilities);
}

function normalizeClassName(className) {
  return `.${(0, _escapeClassName.default)(_lodash.default.trimStart(className, '.'))}`;
}

function findClass(classToApply, classTable, onError) {
  const matches = _lodash.default.get(classTable, classToApply, []);

  if (_lodash.default.isEmpty(matches)) {
    return [];
  }

  if (matches.length > 1) {
    // prettier-ignore
    throw onError(`\`@apply\` cannot be used with ${classToApply} because ${classToApply} is included in multiple rulesets.`);
  }

  const [match] = matches;

  if (match.parent.type !== 'root') {
    // prettier-ignore
    throw onError(`\`@apply\` cannot be used with ${classToApply} because ${classToApply} is nested inside of an at-rule (@${match.parent.name}).`);
  }

  return match.clone().nodes;
}

let shadowLookup = null;

function _default(config, getProcessedPlugins, configChanged) {
  if ((0, _featureFlags.flagEnabled)(config, 'applyComplexClasses')) {
    return (0, _applyComplexClasses.default)(config, getProcessedPlugins, configChanged);
  }

  return function (css) {
    const classLookup = buildClassTable(css);
    shadowLookup = configChanged || !shadowLookup ? buildShadowTable(getProcessedPlugins().utilities) : shadowLookup;
    css.walkRules(rule => {
      rule.walkAtRules('apply', atRule => {
        const classesAndProperties = _postcss.default.list.space(atRule.params);
        /*
         * Don't wreck CSSNext-style @apply rules:
         * http://cssnext.io/features/#custom-properties-set-apply
         *
         * These are deprecated in CSSNext but still playing it safe for now.
         * We might consider renaming this at-rule.
         */


        const [customProperties, classes] = _lodash.default.partition(classesAndProperties, classOrProperty => {
          return _lodash.default.startsWith(classOrProperty, '--');
        });

        const decls = (0, _lodash.default)(classes).reject(cssClass => cssClass === '!important').flatMap(cssClass => {
          const classToApply = normalizeClassName(cssClass);

          const onError = message => {
            return atRule.error(message);
          };

          return _lodash.default.reduce([// Find exact class match in user's CSS
          () => {
            return findClass(classToApply, classLookup, onError);
          }, // Find exact class match in shadow lookup
          () => {
            return findClass(classToApply, shadowLookup, onError);
          }, // Find prefixed version of class in shadow lookup
          () => {
            return findClass((0, _prefixSelector.default)(config.prefix, classToApply), shadowLookup, onError);
          }, // Find important-scoped version of class in shadow lookup
          () => {
            return findClass((0, _increaseSpecificity.default)(config.important, classToApply), shadowLookup, onError);
          }, // Find important-scoped and prefixed version of class in shadow lookup
          () => {
            return findClass((0, _increaseSpecificity.default)(config.important, (0, _prefixSelector.default)(config.prefix, classToApply)), shadowLookup, onError);
          }, () => {
            // prettier-ignore
            throw onError(`\`@apply\` cannot be used with \`${classToApply}\` because \`${classToApply}\` either cannot be found, or its actual definition includes a pseudo-selector like :hover, :active, etc. If you're sure that \`${classToApply}\` exists, make sure that any \`@import\` statements are being properly processed *before* Tailwind CSS sees your CSS, as \`@apply\` can only be used for classes in the same CSS tree.`);
          }], (classDecls, candidate) => !_lodash.default.isEmpty(classDecls) ? classDecls : candidate(), []);
        }).value();

        _lodash.default.tap(_lodash.default.last(classesAndProperties) === '!important', important => {
          decls.forEach(decl => decl.important = important);
        });

        atRule.before(decls);
        atRule.params = customProperties.join(' ');

        if (_lodash.default.isEmpty(customProperties)) {
          atRule.remove();
        }
      });
    });
  };
}