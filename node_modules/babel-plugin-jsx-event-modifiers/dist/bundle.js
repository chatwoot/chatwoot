'use strict';

function _interopDefault (ex) { return (ex && (typeof ex === 'object') && 'default' in ex) ? ex['default'] : ex; }

var syntaxJsx = _interopDefault(require('babel-plugin-syntax-jsx'));

var groupEventAttributes = (function (t) {
  return function (obj, attribute) {
    if (t.isJSXSpreadAttribute(attribute)) {
      return obj;
    }

    var isNamespaced = t.isJSXNamespacedName(attribute.get('name'));
    var event = (isNamespaced ? attribute.get('name').get('namespace') : attribute.get('name')).get('name').node;
    var modifiers = isNamespaced ? new Set(attribute.get('name').get('name').get('name').node.split('-')) : new Set();

    if (event.indexOf('on') !== 0) {
      return obj;
    }

    var value = attribute.get('value');

    attribute.remove();
    if (!t.isJSXExpressionContainer(value)) {
      return obj;
    }

    var expression = value.get('expression').node;

    var eventName = event.substr(2);
    if (eventName[0] === '-') {
      eventName = eventName.substr(1);
    }
    eventName = eventName[0].toLowerCase() + eventName.substr(1);
    if (modifiers.has('capture')) {
      eventName = '!' + eventName;
    }
    if (modifiers.has('once')) {
      eventName = '~' + eventName;
    }

    if (!obj[eventName]) {
      obj[eventName] = [];
    }

    obj[eventName].push({ modifiers, expression, attribute });

    return obj;
  };
});

var aliases = {
  esc: 27,
  tab: 9,
  enter: 13,
  space: 32,
  up: 38,
  left: 37,
  right: 39,
  down: 40,
  delete: [8, 46]
};

var keyModifiers = ['ctrl', 'shift', 'alt', 'meta'];

var keyCodeRE = /^k(\d{1,})$/;

var generateBindingBody = (function (t, _ref) {
  var modifiers = _ref.modifiers,
      expression = _ref.expression;

  var callStatement = t.expressionStatement(t.callExpression(expression, [t.identifier('$event'), t.spreadElement(t.identifier('attrs'))]));
  var result = [];
  var conditions = [];
  var keyConditions = [t.unaryExpression('!', t.binaryExpression('in', t.stringLiteral('button'), t.identifier('$event')))];

  modifiers.forEach(function (modifier) {
    if (modifier === 'stop') {
      result.push(t.expressionStatement(t.callExpression(t.memberExpression(t.identifier('$event'), t.identifier('stopPropagation')), [])));
    } else if (modifier === 'prevent') {
      result.push(t.expressionStatement(t.callExpression(t.memberExpression(t.identifier('$event'), t.identifier('preventDefault')), [])));
    } else if (modifier === 'self') {
      conditions.push(t.binaryExpression('!==', t.memberExpression(t.identifier('$event'), t.identifier('target')), t.memberExpression(t.identifier('$event'), t.identifier('currentTarget'))));
    } else if (keyModifiers.includes(modifier)) {
      conditions.push(t.unaryExpression('!', t.memberExpression(t.identifier('$event'), t.identifier(`${modifier}Key`))));
    } else if (modifier === 'bare') {
      conditions.push(keyModifiers.filter(function (keyModifier) {
        return !modifiers.has(keyModifier);
      }).map(function (keyModifier) {
        return t.memberExpression(t.identifier('$event'), t.identifier(`${keyModifier}Key`));
      }).reduce(function (leftCondition, rightCondition) {
        return t.logicalExpression('||', leftCondition, rightCondition);
      }));
    } else if (aliases[modifier]) {
      keyConditions.push(t.callExpression(t.memberExpression(t.thisExpression(), t.identifier('_k')), [t.memberExpression(t.identifier('$event'), t.identifier('keyCode')), t.stringLiteral(modifier), Array.isArray(aliases[modifier]) ? t.arrayExpression(aliases[modifier].map(function (el) {
        return t.numericLiteral(el);
      })) : t.numericLiteral(aliases[modifier])]));
    } else if (modifier.match(keyCodeRE)) {
      var keyCode = +modifier.match(keyCodeRE)[1];
      keyConditions.push(t.binaryExpression('!==', t.memberExpression(t.identifier('$event'), t.identifier('keyCode')), t.numericLiteral(keyCode)));
    }
  });

  if (keyConditions.length > 1) {
    conditions.push(keyConditions.reduce(function (leftCondition, rightCondition) {
      return t.logicalExpression('&&', leftCondition, rightCondition);
    }));
  }

  if (conditions.length > 0) {
    result.push(t.ifStatement(conditions.reduce(function (leftCondition, rightCondition) {
      return t.logicalExpression('||', leftCondition, rightCondition);
    }), t.returnStatement(t.nullLiteral())));
  }

  result.push(callStatement);
  return result;
});

var generateBindingsList = (function (t, bindings) {
  return bindings.map(function (binding) {
    return t.arrowFunctionExpression([t.identifier('$event'), t.restElement(t.identifier('attrs'))], t.blockStatement(generateBindingBody(t, binding)));
  });
});

var _slicedToArray = function () { function sliceIterator(arr, i) { var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"]) _i["return"](); } finally { if (_d) throw _e; } } return _arr; } return function (arr, i) { if (Array.isArray(arr)) { return arr; } else if (Symbol.iterator in Object(arr)) { return sliceIterator(arr, i); } else { throw new TypeError("Invalid attempt to destructure non-iterable instance"); } }; }();

var generateSpreadEvent = (function (t) {
  return function (_ref) {
    var _ref2 = _slicedToArray(_ref, 2),
        event = _ref2[0],
        bindings = _ref2[1];

    var callbacks = generateBindingsList(t, bindings);
    return t.objectProperty(t.stringLiteral(event), callbacks.length === 1 ? callbacks[0] : t.arrayExpression(callbacks));
  };
});

var index = (function (_ref) {
  var t = _ref.types;
  return {
    inherits: syntaxJsx,
    visitor: {
      Program(path) {
        path.traverse({
          JSXOpeningElement(path) {
            var attributes = path.get('attributes');
            var groupedEventAttributes = attributes.reduce(groupEventAttributes(t), {});
            var events = Object.keys(groupedEventAttributes).map(function (key) {
              return [key, groupedEventAttributes[key]];
            });
            if (events.length > 0) {
              path.pushContainer('attributes', t.jSXSpreadAttribute(t.objectExpression([t.objectProperty(t.identifier('on'), t.objectExpression(events.map(generateSpreadEvent(t))))])));
            }
          }
        });
      }
    }
  };
});

module.exports = index;
