"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.extractEventHiddenProperties = extractEventHiddenProperties;

function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); if (enumerableOnly) symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; }); keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i] != null ? arguments[i] : {}; if (i % 2) { ownKeys(Object(source), true).forEach(function (key) { _defineProperty(target, key, source[key]); }); } else if (Object.getOwnPropertyDescriptors) { Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)); } else { ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

var eventProperties = ['bubbles', 'cancelBubble', 'cancelable', 'composed', 'currentTarget', 'defaultPrevented', 'eventPhase', 'isTrusted', 'returnValue', 'srcElement', 'target', 'timeStamp', 'type'];
var customEventSpecificProperties = ['detail'];
/**
 * Dom Event (and all its subclasses) is built in a way its internal properties
 * are accessible when querying them directly but "hidden" when iterating its
 * keys.
 *
 * With a code example it means: `Object.keys(new Event('click')) = ["isTrusted"]`
 *
 * So to be able to stringify/parse more than just `isTrusted` info we need to
 * create a new object and set the properties by hand. As there is no way to
 * iterate the properties we rely on a list of hardcoded properties.
 *
 * @param event The event we want to extract properties
 */

function extractEventHiddenProperties(event) {
  var rebuildEvent = eventProperties.filter(function (value) {
    return event[value] !== undefined;
  }).reduce(function (acc, value) {
    return _objectSpread(_objectSpread({}, acc), {}, _defineProperty({}, value, event[value]));
  }, {});

  if (event instanceof CustomEvent) {
    customEventSpecificProperties.filter(function (value) {
      return event[value] !== undefined;
    }).forEach(function (value) {
      rebuildEvent[value] = event[value];
    });
  }

  return rebuildEvent;
}