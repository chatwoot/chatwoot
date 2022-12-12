import { getExplicitRole } from '../commons/aria';
import { querySelectorAll } from '../core/utils';
import getElementSpec from '../commons/standards/get-element-spec';

/**
 * Filter out elements that have a naming method (i.e. img[alt], table > caption, etc.)
 */
function noNamingMethodMatches(node, virtualNode) {
  const { namingMethods } = getElementSpec(virtualNode);
  if (namingMethods && namingMethods.length !== 0) {
    return false;
  }

  // Additionally, ignore combobox that get their name from a descendant input:
  if (
    getExplicitRole(virtualNode) === 'combobox' &&
    querySelectorAll(virtualNode, 'input:not([type="hidden"])').length
  ) {
    return false;
  }
  return true;
}

export default noNamingMethodMatches;
