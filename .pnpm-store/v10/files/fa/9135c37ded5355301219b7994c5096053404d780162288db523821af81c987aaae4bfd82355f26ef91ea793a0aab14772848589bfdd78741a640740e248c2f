"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isElementInToolbar = isElementInToolbar;
exports.isElementNode = isElementNode;
exports.isTag = isTag;
exports.isTextNode = isTextNode;
exports.isDocumentFragment = isDocumentFragment;
var constants_1 = require("../constants");
function isElementInToolbar(el) {
    var _a;
    if (el instanceof Element) {
        // closest isn't available in IE11, but we'll polyfill when bundling
        return el.id === constants_1.TOOLBAR_ID || !!((_a = el.closest) === null || _a === void 0 ? void 0 : _a.call(el, '.' + constants_1.TOOLBAR_CONTAINER_CLASS));
    }
    return false;
}
/*
 * Check whether an element has nodeType Node.ELEMENT_NODE
 * @param {Element} el - element to check
 * @returns {boolean} whether el is of the correct nodeType
 */
function isElementNode(el) {
    return !!el && el.nodeType === 1; // Node.ELEMENT_NODE - use integer constant for browser portability
}
/*
 * Check whether an element is of a given tag type.
 * Due to potential reference discrepancies (such as the webcomponents.js polyfill),
 * we want to match tagNames instead of specific references because something like
 * element === document.body won't always work because element might not be a native
 * element.
 * @param {Element} el - element to check
 * @param {string} tag - tag name (e.g., "div")
 * @returns {boolean} whether el is of the given tag type
 */
function isTag(el, tag) {
    return !!el && !!el.tagName && el.tagName.toLowerCase() === tag.toLowerCase();
}
/*
 * Check whether an element has nodeType Node.TEXT_NODE
 * @param {Element} el - element to check
 * @returns {boolean} whether el is of the correct nodeType
 */
function isTextNode(el) {
    return !!el && el.nodeType === 3; // Node.TEXT_NODE - use integer constant for browser portability
}
/*
 * Check whether an element has nodeType Node.DOCUMENT_FRAGMENT_NODE
 * @param {Element} el - element to check
 * @returns {boolean} whether el is of the correct nodeType
 */
function isDocumentFragment(el) {
    return !!el && el.nodeType === 11; // Node.DOCUMENT_FRAGMENT_NODE - use integer constant for browser portability
}
//# sourceMappingURL=element-utils.js.map