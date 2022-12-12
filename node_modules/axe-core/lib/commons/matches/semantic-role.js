import fromPrimative from './from-primative';
import getRole from '../aria/get-role';

/**
 * Check if a virtual node matches an semantic role(s)
 *``
 * Note: matches.semanticRole(vNode, matcher) can be indirectly used through
 * matches(vNode, { semanticRole: matcher })
 *
 * Example:
 * ```js
 * matches.semanticRole(vNode, ['combobox', 'textbox']);
 * matches.semanticRole(vNode, 'combobox');
 * ```
 *
 * @param {VirtualNode} vNode
 * @param {Object} matcher
 * @returns {Boolean}
 */
function semanticRole(vNode, matcher) {
  return fromPrimative(getRole(vNode), matcher);
}

export default semanticRole;
