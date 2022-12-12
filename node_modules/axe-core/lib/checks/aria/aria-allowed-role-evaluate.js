import { isVisible } from '../../commons/dom';
import { getElementUnallowedRoles } from '../../commons/aria';

/**
 * Check if an element is allowed to have its explicit role value.
 *
 * Allowed ARIA roles are taken from the `htmlElms` standards object from the elements `allowedRoles` property.
 *
 * @memberof checks
 * @param {Boolean} [options.allowImplicit=true] Allow the explicit role to match the implicit role of the element.
 * @param {String[]} [options.ignoredTags=[]] Do not check for allowed roles in the provided HTML elements list.
 * @data {String[]} List of all unallowed roles.
 * @return {Boolean} True if the role is allowed on the element. False otherwise.
 */
function ariaAllowedRoledEvaluate(node, options = {}) {
  /**
   * Implements allowed roles defined at:
   * https://www.w3.org/TR/html-aria/#docconformance
   * https://www.w3.org/TR/SVG2/struct.html#implicit-aria-semantics
   */
  const { allowImplicit = true, ignoredTags = [] } = options;
  const tagName = node.nodeName.toUpperCase();

  // check if the element should be ignored, by an user setting
  if (ignoredTags.map(t => t.toUpperCase()).includes(tagName)) {
    return true;
  }

  const unallowedRoles = getElementUnallowedRoles(node, allowImplicit);

  if (unallowedRoles.length) {
    this.data(unallowedRoles);
    if (!isVisible(node, true)) {
      // flag hidden elements for review
      return undefined;
    }
    return false;
  }
  return true;
}

export default ariaAllowedRoledEvaluate;
