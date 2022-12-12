import getExplicitRole from './get-explicit-role';
import getImplicitRole from './implicit-role';
import getGlobalAriaAttrs from '../standards/get-global-aria-attrs';
import isFocusable from '../dom/is-focusable';
import { getNodeFromTree } from '../../core/utils';
import AbstractVirtuaNode from '../../core/base/virtual-node/abstract-virtual-node';

// when an element inherits the presentational role from a parent
// is not defined in the spec, but through testing it seems to be
// when a specific HTML parent relationship is required and that
// parent has `role=presentation`, then the child inherits the
// role (i.e. table, ul, dl). Further testing has shown that
// intermediate elements (such as divs) break this chain only in
// Chrome.
//
// Also, any nested structure chains reset the role (so two nested
// lists with the topmost list role=none will not cause the nested
// list to inherit the role=none).
//
// from Scott O'Hara:
//
// "the expectation for me, in standard html is that element
// structures that require specific parent/child relationships,
// if the parent is set to presentational that should set the
// children to presentational.  ala, tables and lists."
// "but outside of those specific constructs, i would not expect
// role=presentation to do anything to child element roles"
const inheritsPresentationChain = {
  // valid parent elements, any other element will prevent any
  // children from inheriting a presentational role from a valid
  // ancestor
  td: ['tr'],
  th: ['tr'],
  tr: ['thead', 'tbody', 'tfoot', 'table'],
  thead: ['table'],
  tbody: ['table'],
  tfoot: ['table'],
  li: ['ol', 'ul'],
  // dts and dds can be wrapped in divs and the div will pass through
  // the presentation role
  dt: ['dl', 'div'],
  dd: ['dl', 'div'],
  div: ['dl']
};

// role presentation inheritance.
// Source: https://www.w3.org/TR/wai-aria-1.1/#conflict_resolution_presentation_none
function getInheritedRole(vNode, explicitRoleOptions) {
  const parentNodeNames = inheritsPresentationChain[vNode.props.nodeName];
  if (!parentNodeNames) {
    return null;
  }

  // if we can't look at the parent then we can't know if the node
  // inherits the presentational role or not
  if (!vNode.parent) {
    throw new ReferenceError(
      'Cannot determine role presentational inheritance of a required parent outside the current scope.'
    );
  }

  // parent is not a valid ancestor that can inherit presentation
  if (!parentNodeNames.includes(vNode.parent.props.nodeName)) {
    return null;
  }

  const parentRole = getExplicitRole(vNode.parent, explicitRoleOptions);
  if (
    ['none', 'presentation'].includes(parentRole) &&
    !hasConflictResolution(vNode.parent)
  ) {
    return parentRole;
  }

  // an explicit role of anything other than presentational will
  // prevent any children from inheriting a presentational role
  // from a valid ancestor
  if (parentRole) {
    return null;
  }

  return getInheritedRole(vNode.parent, explicitRoleOptions);
}

function resolveImplicitRole(vNode, explicitRoleOptions) {
  const implicitRole = getImplicitRole(vNode);

  if (!implicitRole) {
    return null;
  }

  const presentationalRole = getInheritedRole(vNode, explicitRoleOptions);
  if (presentationalRole) {
    return presentationalRole;
  }

  return implicitRole;
}

// role conflict resolution
// note: Chrome returns a list with resolved role as "generic"
// instead of as a list
// (e.g. <ul role="none" aria-label><li>hello</li></ul>)
// we will return it as a list as that is the best option.
// Source: https://www.w3.org/TR/wai-aria-1.1/#conflict_resolution_presentation_none
// See also: https://github.com/w3c/aria/issues/1270
function hasConflictResolution(vNode) {
  const hasGlobalAria = getGlobalAriaAttrs().some(attr => vNode.hasAttr(attr));
  return hasGlobalAria || isFocusable(vNode);
}

/**
 *
 * @method resolveRole
 * @param {Element|VirtualNode} node
 * @param {Object} options
 * @see getRole for option details
 * @returns {string|null} Role or null
 * @deprecated noImplicit option is deprecated. Use aria.getExplicitRole instead.
 */
function resolveRole(node, { noImplicit, ...explicitRoleOptions } = {}) {
  const vNode =
    node instanceof AbstractVirtuaNode ? node : getNodeFromTree(node);
  if (vNode.props.nodeType !== 1) {
    return null;
  }

  const explicitRole = getExplicitRole(vNode, explicitRoleOptions);

  if (!explicitRole) {
    return noImplicit ? null : resolveImplicitRole(vNode, explicitRoleOptions);
  }

  if (!['presentation', 'none'].includes(explicitRole)) {
    return explicitRole;
  }

  if (hasConflictResolution(vNode)) {
    // return null if there is a conflict resolution but no implicit
    // has been set as the explicit role is not the true role
    return noImplicit ? null : resolveImplicitRole(vNode, explicitRoleOptions);
  }

  // role presentation or none and no conflict resolution
  return explicitRole;
}

/**
 * Return the semantic role of an element.
 *
 * @method getRole
 * @memberof axe.commons.aria
 * @instance
 * @param {Element|VirtualNode} node
 * @param {Object} options
 * @param {boolean} options.noImplicit  Do not return the implicit role // @deprecated
 * @param {boolean} options.fallback  Allow fallback roles
 * @param {boolean} options.abstracts  Allow role to be abstract
 * @param {boolean} options.dpub  Allow role to be any (valid) doc-* roles
 * @param {boolean} options.noPresentational return null if role is presentation or none
 * @returns {string|null} Role or null
 *
 * @deprecated noImplicit option is deprecated. Use aria.getExplicitRole instead.
 */
function getRole(node, { noPresentational, ...options } = {}) {
  const role = resolveRole(node, options);

  if (noPresentational && ['presentation', 'none'].includes(role)) {
    return null;
  }

  return role;
}

export default getRole;
