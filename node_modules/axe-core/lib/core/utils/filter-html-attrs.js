import cache from '../base/cache';
import getNodeAttributes from './get-node-attributes';
import matchesSelector from './element-matches';

/**
 * Test if node and attribute match one of the filtered attributes.
 * @param {HTMLElement} node - node to match
 * @param {String} attrname - Name of the attribute to test
 * @param {Object} filterAttrs - Attributes to remove and the qualifier of when to remove them.
 */
function attributeMatches(node, attrName, filterAttrs) {
  if (typeof filterAttrs[attrName] === 'undefined') {
    return false;
  }

  // filterAttrs can only be a boolean or a CSS selector
  if (filterAttrs[attrName] === true) {
    return true;
  }

  return matchesSelector(node, filterAttrs[attrName]);
}

/**
 * Filter attributes from an html element and all of its children.
 *
 * Example:
 * ```js
 * // Remove attribute if present
 * axe.utils.filterHtmlAttrs('<div data-attr="foo">my div</div>', { 'data-attr': true });
 *
 * // Remove attribute if CSS selector matches
 * axe.utils.filterHtmlAttrs('<div data-attr="foo">my div</div>', { 'data-attr': 'div' });
 * ```
 *
 * @method filterHtmlAttrs
 * @memberof axe.utils
 * @param {HTMLElement} element - HTML element to remove attributes from
 * @param {Object} filterAttrs - Attributes to remove and the qualifier of when to remove them
 * @returns {HTMLElement} Element with filtered attributes removed
 */
function filterHtmlAttrs(element, filterAttrs) {
  if (!filterAttrs) {
    return element;
  }

  let node = element.cloneNode(false);
  const outerHTML = node.outerHTML;
  const attributes = getNodeAttributes(node);

  if (cache.get(outerHTML)) {
    node = cache.get(outerHTML);
  } else if (attributes) {
    node = document.createElement(node.nodeName);
    Array.from(attributes).forEach(attr => {
      if (!attributeMatches(element, attr.name, filterAttrs)) {
        // can't remove the value attribute from an input in IE11 so
        // we'll have to reconstruct the node and set attribute
        // manually
        node.setAttribute(attr.name, attr.value);
      }
    });

    cache.set(outerHTML, node);
  }

  // be sure to append text nodes as well
  Array.from(element.childNodes).forEach(child => {
    node.appendChild(filterHtmlAttrs(child, filterAttrs));
  });

  return node;
}

export default filterHtmlAttrs;
