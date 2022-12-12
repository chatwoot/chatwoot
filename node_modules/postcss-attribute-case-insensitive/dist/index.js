"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _postcss = _interopRequireDefault(require("postcss"));

var _postcssSelectorParser = _interopRequireDefault(require("postcss-selector-parser"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function nodeIsInsensitiveAttribute(node) {
  return node.type === 'attribute' && node.insensitive;
}

function selectorHasInsensitiveAttribute(selector) {
  return selector.some(nodeIsInsensitiveAttribute);
}

function transformString(strings, charPos, string) {
  var char = string.charAt(charPos);

  if (char === '') {
    return strings;
  }

  var newStrings = strings.map(function (x) {
    return x + char;
  });
  var upperChar = char.toLocaleUpperCase();

  if (upperChar !== char) {
    newStrings = newStrings.concat(strings.map(function (x) {
      return x + upperChar;
    }));
  }

  return transformString(newStrings, charPos + 1, string);
}

function createSensitiveAtributes(attribute) {
  var attributes = transformString([''], 0, attribute.value);
  return attributes.map(function (x) {
    var newAttribute = attribute.clone({
      spaces: {
        after: attribute.spaces.after,
        before: attribute.spaces.before
      },
      insensitive: false
    });
    newAttribute.setValue(x);
    return newAttribute;
  });
}

function createNewSelectors(selector) {
  var newSelectors = [_postcssSelectorParser.default.selector()];
  selector.walk(function (node) {
    if (!nodeIsInsensitiveAttribute(node)) {
      newSelectors.forEach(function (newSelector) {
        newSelector.append(node.clone());
      });
      return;
    }

    var sensitiveAttributes = createSensitiveAtributes(node);
    var newSelectorsWithSensitiveAttributes = [];
    sensitiveAttributes.forEach(function (newNode) {
      newSelectors.forEach(function (newSelector) {
        var newSelectorWithNewNode = newSelector.clone();
        newSelectorWithNewNode.append(newNode);
        newSelectorsWithSensitiveAttributes.push(newSelectorWithNewNode);
      });
    });
    newSelectors = newSelectorsWithSensitiveAttributes;
  });
  return newSelectors;
}

function transform(selectors) {
  var newSelectors = [];
  selectors.each(function (selector) {
    if (selectorHasInsensitiveAttribute(selector)) {
      newSelectors = newSelectors.concat(createNewSelectors(selector));
      selector.remove();
    }
  });

  if (newSelectors.length) {
    newSelectors.forEach(function (newSelector) {
      return selectors.append(newSelector);
    });
  }
}

var caseInsensitiveRegExp = /i(\s*\/\*[\W\w]*?\*\/)*\s*\]/;

var _default = _postcss.default.plugin('postcss-attribute-case-insensitive', function () {
  return function (css) {
    css.walkRules(caseInsensitiveRegExp, function (rule) {
      rule.selector = (0, _postcssSelectorParser.default)(transform).processSync(rule.selector);
    });
  };
});

exports.default = _default;