import attributes from './attributes';
import condition from './condition';
import explicitRole from './explicit-role';
import implicitRole from './implicit-role';
import nodeName from './node-name';
import properties from './properties';
import semanticRole from './semantic-role';
import AbstractVirtualNode from '../../core/base/virtual-node/abstract-virtual-node';
import { getNodeFromTree, matches } from '../../core/utils';

const matchers = {
  attributes,
  condition,
  explicitRole,
  implicitRole,
  nodeName,
  properties,
  semanticRole
};

/**
 * Check if a virtual node matches some definition
 *
 * Note: matches.fromDefinition(vNode, definition) can be indirectly used through
 * matches(vNode, definition)
 *
 * Example:
 * ```js
 * matches.fromDefinition(vNode, {
 *   nodeName: ['div', 'span']
 *   attributes: {
 *     'aria-live': 'assertive'
 *   }
 * })
 * ```
 *
 * @deprecated HTMLElement is deprecated, use VirtualNode instead
 *
 * @private
 * @param {HTMLElement|VirtualNode} vNode
 * @param {Object|Array<Object>} definition
 * @returns {Boolean}
 */
function fromDefinition(vNode, definition) {
  if (!(vNode instanceof AbstractVirtualNode)) {
    vNode = getNodeFromTree(vNode);
  }

  if (Array.isArray(definition)) {
    return definition.some(definitionItem =>
      fromDefinition(vNode, definitionItem)
    );
  }
  if (typeof definition === 'string') {
    return matches(vNode, definition);
  }

  return Object.keys(definition).every(matcherName => {
    if (!matchers[matcherName]) {
      throw new Error(`Unknown matcher type "${matcherName}"`);
    }
    // Find the specific matches method to.
    // matches.attributes, matches.nodeName, matches.properties, etc.
    const matchMethod = matchers[matcherName];

    // Find the matcher that goes into the matches method.
    // 'div', /^div$/, (str) => str === 'div', etc.
    const matcher = definition[matcherName];
    return matchMethod(vNode, matcher);
  });
}

export default fromDefinition;
