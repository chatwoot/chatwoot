import { hasContentVirtual } from '../commons/dom';
import { getExplicitRole } from '../commons/aria';
import standards from '../standards';
import {
  querySelectorAll,
  getScroll,
  closest,
  getRootNode,
  tokenList
} from '../core/utils';

function scrollableRegionFocusableMatches(node, virtualNode) {
  /**
   * Note:
   * `excludeHidden=true` for this rule, thus considering only elements in the accessibility tree.
   */

  /**
   * if not scrollable -> `return`
   */
  if (!!getScroll(node, 13) === false) {
    return false;
  }

  /**
   * ignore scrollable regions owned by combobox. limit to roles
   * ownable by combobox so we don't keep calling closest for every
   * node (which would be slow)
   * @see https://github.com/dequelabs/axe-core/issues/1763
   */
  const role = getExplicitRole(virtualNode);
  if (standards.ariaRoles.combobox.requiredOwned.includes(role)) {
    // in ARIA 1.1 the container has role=combobox
    if (closest(virtualNode, '[role~="combobox"]')) {
      return false;
    }

    // in ARIA 1.0 and 1.2 the combobox owns (1.0) or controls (1.2)
    // the listbox
    const id = virtualNode.attr('id');
    if (id) {
      const doc = getRootNode(node);
      const owned = Array.from(
        doc.querySelectorAll(`[aria-owns~="${id}"], [aria-controls~="${id}"]`)
      );
      const comboboxOwned = owned.some(el => {
        const roles = tokenList(el.getAttribute('role'));
        return roles.includes('combobox');
      });

      if (comboboxOwned) {
        return false;
      }
    }
  }

  /**
   * check if node has visible contents
   */
  const nodeAndDescendents = querySelectorAll(virtualNode, '*');
  const hasVisibleChildren = nodeAndDescendents.some(elm =>
    hasContentVirtual(
      elm,
      true, // noRecursion
      true // ignoreAria
    )
  );
  if (!hasVisibleChildren) {
    return false;
  }

  return true;
}

export default scrollableRegionFocusableMatches;
