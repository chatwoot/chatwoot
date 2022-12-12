"use strict";

var _interopRequireDefault = require("@babel/runtime/helpers/interopRequireDefault");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = void 0;

var _slicedToArray2 = _interopRequireDefault(require("@babel/runtime/helpers/slicedToArray"));

var _toConsumableArray2 = _interopRequireDefault(require("@babel/runtime/helpers/toConsumableArray"));

var _ariaQuery = require("aria-query");

var _axobjectQuery = require("axobject-query");

var _arrayIncludes = _interopRequireDefault(require("array-includes"));

var _attributesComparator = _interopRequireDefault(require("./attributesComparator"));

var roleKeys = (0, _toConsumableArray2["default"])(_ariaQuery.roles.keys());
var elementRoleEntries = (0, _toConsumableArray2["default"])(_ariaQuery.elementRoles);
var nonInteractiveRoles = new Set(roleKeys.filter(function (name) {
  var role = _ariaQuery.roles.get(name);

  return !role["abstract"] // 'toolbar' does not descend from widget, but it does support
  // aria-activedescendant, thus in practice we treat it as a widget.
  && name !== 'toolbar' // This role is meant to have no semantic value.
  // @see https://www.w3.org/TR/wai-aria-1.2/#generic
  && name !== 'generic' && !role.superClass.some(function (classes) {
    return (0, _arrayIncludes["default"])(classes, 'widget');
  });
}).concat( // The `progressbar` is descended from `widget`, but in practice, its
// value is always `readonly`, so we treat it as a non-interactive role.
'progressbar'));
var interactiveRoles = new Set(roleKeys.filter(function (name) {
  var role = _ariaQuery.roles.get(name);

  return !role["abstract"] // The `progressbar` is descended from `widget`, but in practice, its
  // value is always `readonly`, so we treat it as a non-interactive role.
  && name !== 'progressbar' // This role is meant to have no semantic value.
  // @see https://www.w3.org/TR/wai-aria-1.2/#generic
  && name !== 'generic' && role.superClass.some(function (classes) {
    return (0, _arrayIncludes["default"])(classes, 'widget');
  });
}).concat( // 'toolbar' does not descend from widget, but it does support
// aria-activedescendant, thus in practice we treat it as a widget.
'toolbar'));
var nonInteractiveElementRoleSchemas = elementRoleEntries.reduce(function (accumulator, _ref) {
  var _ref2 = (0, _slicedToArray2["default"])(_ref, 2),
      elementSchema = _ref2[0],
      roleSet = _ref2[1];

  if ((0, _toConsumableArray2["default"])(roleSet).every(function (role) {
    return nonInteractiveRoles.has(role);
  })) {
    accumulator.push(elementSchema);
  }

  return accumulator;
}, []);
var interactiveElementRoleSchemas = elementRoleEntries.reduce(function (accumulator, _ref3) {
  var _ref4 = (0, _slicedToArray2["default"])(_ref3, 2),
      elementSchema = _ref4[0],
      roleSet = _ref4[1];

  if ((0, _toConsumableArray2["default"])(roleSet).some(function (role) {
    return interactiveRoles.has(role);
  })) {
    accumulator.push(elementSchema);
  }

  return accumulator;
}, []);
var nonInteractiveAXObjects = new Set((0, _toConsumableArray2["default"])(_axobjectQuery.AXObjects.keys()).filter(function (name) {
  return (0, _arrayIncludes["default"])(['window', 'structure'], _axobjectQuery.AXObjects.get(name).type);
}));
var nonInteractiveElementAXObjectSchemas = (0, _toConsumableArray2["default"])(_axobjectQuery.elementAXObjects).reduce(function (accumulator, _ref5) {
  var _ref6 = (0, _slicedToArray2["default"])(_ref5, 2),
      elementSchema = _ref6[0],
      AXObjectSet = _ref6[1];

  if ((0, _toConsumableArray2["default"])(AXObjectSet).every(function (role) {
    return nonInteractiveAXObjects.has(role);
  })) {
    accumulator.push(elementSchema);
  }

  return accumulator;
}, []);

function checkIsNonInteractiveElement(tagName, attributes) {
  function elementSchemaMatcher(elementSchema) {
    return tagName === elementSchema.name && (0, _attributesComparator["default"])(elementSchema.attributes, attributes);
  } // Check in elementRoles for inherent non-interactive role associations for
  // this element.


  var isInherentNonInteractiveElement = nonInteractiveElementRoleSchemas.some(elementSchemaMatcher);

  if (isInherentNonInteractiveElement) {
    return true;
  } // Check in elementRoles for inherent interactive role associations for
  // this element.


  var isInherentInteractiveElement = interactiveElementRoleSchemas.some(elementSchemaMatcher);

  if (isInherentInteractiveElement) {
    return false;
  } // Check in elementAXObjects for AX Tree associations for this element.


  var isNonInteractiveAXElement = nonInteractiveElementAXObjectSchemas.some(elementSchemaMatcher);

  if (isNonInteractiveAXElement) {
    return true;
  }

  return false;
}
/**
 * Returns boolean indicating whether the given element is a non-interactive
 * element. If the element has either a non-interactive role assigned or it
 * is an element with an inherently non-interactive role, then this utility
 * returns true. Elements that lack either an explicitly assigned role or
 * an inherent role are not considered. For those, this utility returns false
 * because a positive determination of interactiveness cannot be determined.
 */


var isNonInteractiveElement = function isNonInteractiveElement(tagName, attributes) {
  // Do not test higher level JSX components, as we do not know what
  // low-level DOM element this maps to.
  if (!_ariaQuery.dom.has(tagName)) {
    return false;
  } // <header> elements do not technically have semantics, unless the
  // element is a direct descendant of <body>, and this plugin cannot
  // reliably test that.
  // @see https://www.w3.org/TR/wai-aria-practices/examples/landmarks/banner.html


  if (tagName === 'header') {
    return false;
  }

  return checkIsNonInteractiveElement(tagName, attributes);
};

var _default = isNonInteractiveElement;
exports["default"] = _default;