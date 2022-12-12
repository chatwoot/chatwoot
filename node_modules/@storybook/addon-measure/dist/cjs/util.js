"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.deepElementFromPoint = void 0;

var _global = _interopRequireDefault(require("global"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var deepElementFromPoint = function deepElementFromPoint(x, y) {
  var element = _global.default.document.elementFromPoint(x, y);

  var crawlShadows = function crawlShadows(node) {
    if (node && node.shadowRoot) {
      var nestedElement = node.shadowRoot.elementFromPoint(x, y); // Nested node is same as the root one

      if (node.isEqualNode(nestedElement)) {
        return node;
      } // The nested node has shadow DOM too so continue crawling


      if (nestedElement.shadowRoot) {
        return crawlShadows(nestedElement);
      } // No more shadow DOM


      return nestedElement;
    }

    return node;
  };

  var shadowElement = crawlShadows(element);
  return shadowElement || element;
};

exports.deepElementFromPoint = deepElementFromPoint;