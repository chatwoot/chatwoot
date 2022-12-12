import {
  requiredOwned,
  getRole,
  getExplicitRole,
  getOwnedVirtual
} from '../../commons/aria';
import { hasContentVirtual, idrefs } from '../../commons/dom';

/**
 * Get all owned roles of an element
 */
function getOwnedRoles(virtualNode, required) {
  const ownedRoles = [];
  const ownedElements = getOwnedVirtual(virtualNode);
  for (let i = 0; i < ownedElements.length; i++) {
    const ownedElement = ownedElements[i];
    const role = getRole(ownedElement, { noPresentational: true });

    // if owned node has no role or is presentational, or if role
    // allows group or rowgroup, we keep parsing the descendant tree.
    // this means intermediate roles between a required parent and
    // child will fail the check
    if (
      !role ||
      (['group', 'rowgroup'].includes(role) &&
        required.some(requiredRole => requiredRole === role))
    ) {
      ownedElements.push(...ownedElement.children);
    } else if (role) {
      ownedRoles.push(role);
    }
  }

  return ownedRoles;
}

/**
 * Get missing children roles
 */
function missingRequiredChildren(virtualNode, role, required, ownedRoles) {
  const isCombobox = role === 'combobox';

  // combobox exceptions
  if (isCombobox) {
    // remove 'textbox' from missing roles if combobox is a native
    // text-type input or owns a 'searchbox'
    const textTypeInputs = ['text', 'search', 'email', 'url', 'tel'];
    if (
      (virtualNode.props.nodeName === 'input' &&
        textTypeInputs.includes(virtualNode.props.type)) ||
      ownedRoles.includes('searchbox')
    ) {
      required = required.filter(requiredRole => requiredRole !== 'textbox');
    }

    // combobox only needs one of [listbox, tree, grid, dialog] and
    // only the type that matches the aria-popup value. remove
    // all the other popup roles from the list of required
    const expandedChildRoles = ['listbox', 'tree', 'grid', 'dialog'];
    const expandedValue = virtualNode.attr('aria-expanded');
    const expanded = expandedValue && expandedValue.toLowerCase() !== 'false';
    const popupRole = (
      virtualNode.attr('aria-haspopup') || 'listbox'
    ).toLowerCase();
    required = required.filter(
      requiredRole =>
        !expandedChildRoles.includes(requiredRole) ||
        (expanded && requiredRole === popupRole)
    );
  }

  for (let i = 0; i < ownedRoles.length; i++) {
    var ownedRole = ownedRoles[i];

    if (required.includes(ownedRole)) {
      required = required.filter(requiredRole => requiredRole !== ownedRole);

      // combobox requires all the roles not just any one of them
      if (!isCombobox) {
        return null;
      }
    }
  }

  if (required.length) {
    return required;
  }

  return null;
}

/**
 * Check that an element owns all required children for its explicit role.
 *
 * Required roles are taken from the `ariaRoles` standards object from the roles `requiredOwned` property.
 *
 * @memberof checks
 * @param {Boolean} options.reviewEmpty List of ARIA roles that should be flagged as "Needs Review" rather than a violation if the element has no owned children.
 * @data {String[]} List of all missing owned roles.
 * @returns {Mixed} True if the element owns all required roles. Undefined if `options.reviewEmpty=true` and the element has no owned children. False otherwise.
 */
function ariaRequiredChildrenEvaluate(node, options, virtualNode) {
  const reviewEmpty =
    options && Array.isArray(options.reviewEmpty) ? options.reviewEmpty : [];
  const role = getExplicitRole(virtualNode, { dpub: true });
  const required = requiredOwned(role);
  if (required === null) {
    return true;
  }

  const ownedRoles = getOwnedRoles(virtualNode, required);
  const missing = missingRequiredChildren(
    virtualNode,
    role,
    required,
    ownedRoles
  );
  if (!missing) {
    return true;
  }

  this.data(missing);

  // Only review empty nodes when a node is both empty and does not have an aria-owns relationship
  if (
    reviewEmpty.includes(role) &&
    !hasContentVirtual(virtualNode, false, true) &&
    !ownedRoles.length &&
    (!virtualNode.hasAttr('aria-owns') || !idrefs(node, 'aria-owns').length)
  ) {
    return undefined;
  }

  return false;
}

export default ariaRequiredChildrenEvaluate;
