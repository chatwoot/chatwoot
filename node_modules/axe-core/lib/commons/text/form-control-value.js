import getRole from '../aria/get-role';
import unsupported from './unsupported';
import visibleVirtual from './visible-virtual';
import accessibleTextVirtual from './accessible-text-virtual';
import isNativeTextbox from '../forms/is-native-textbox';
import isNativeSelect from '../forms/is-native-select';
import isAriaTextbox from '../forms/is-aria-textbox';
import isAriaListbox from '../forms/is-aria-listbox';
import isAriaCombobox from '../forms/is-aria-combobox';
import isAriaRange from '../forms/is-aria-range';
import getOwnedVirtual from '../aria/get-owned-virtual';
import isHiddenWithCSS from '../dom/is-hidden-with-css';
import AbstractVirtualNode from '../../core/base/virtual-node/abstract-virtual-node';
import { getNodeFromTree, querySelectorAll } from '../../core/utils';
import log from '../../core/log';

const controlValueRoles = [
  'textbox',
  'progressbar',
  'scrollbar',
  'slider',
  'spinbutton',
  'combobox',
  'listbox'
];

export const formControlValueMethods = {
  nativeTextboxValue,
  nativeSelectValue,
  ariaTextboxValue,
  ariaListboxValue,
  ariaComboboxValue,
  ariaRangeValue
};

/**
 * Calculate value of a form control
 *
 * @param {VirtualNode} element The VirtualNode instance whose value we want
 * @param {Object} context
 * @property {Element} startNode First node in accessible name computation
 * @property {String[]} unsupported List of roles where value computation is unsupported
 * @property {Bool} debug Enable logging for formControlValue
 * @return {string} The calculated value
 */
function formControlValue(virtualNode, context = {}) {
  const { actualNode } = virtualNode;
  const unsupportedRoles = unsupported.accessibleNameFromFieldValue || [];
  const role = getRole(virtualNode);

  if (
    // For the targeted node, the accessible name is never the value:
    context.startNode === virtualNode ||
    // Only elements with a certain role can return their value
    !controlValueRoles.includes(role) ||
    // Skip unsupported roles
    unsupportedRoles.includes(role)
  ) {
    return '';
  }

  // Object.values:
  const valueMethods = Object.keys(formControlValueMethods).map(
    name => formControlValueMethods[name]
  );

  // Return the value of the first step that returns with text
  const valueString = valueMethods.reduce((accName, step) => {
    return accName || step(virtualNode, context);
  }, '');

  if (context.debug) {
    log(valueString || '{empty-value}', actualNode, context);
  }
  return valueString;
}

/**
 * Calculate value of a native textbox element (input and textarea)
 *
 * @param {VirtualNode|Element} element The element whose value we want
 * @return {string} The calculated value
 */
function nativeTextboxValue(node) {
  const vNode =
    node instanceof AbstractVirtualNode ? node : getNodeFromTree(node);

  if (isNativeTextbox(vNode)) {
    return vNode.props.value || '';
  }
  return '';
}

/**
 * Calculate value of a select element
 *
 * @param {VirtualNode} element The VirtualNode instance whose value we want
 * @return {string} The calculated value
 */
function nativeSelectValue(node) {
  const vNode =
    node instanceof AbstractVirtualNode ? node : getNodeFromTree(node);

  if (!isNativeSelect(vNode)) {
    return '';
  }

  const options = querySelectorAll(vNode, 'option');
  const selectedOptions = options.filter(option => option.hasAttr('selected'));

  // browser automatically selects the first option
  if (!selectedOptions.length) {
    selectedOptions.push(options[0]);
  }

  return selectedOptions.map(option => visibleVirtual(option)).join(' ') || '';
}

/**
 * Calculate value of a an element with role=textbox
 *
 * @param {VirtualNode} element The VirtualNode instance whose value we want
 * @return {string} The calculated value
 */
function ariaTextboxValue(node) {
  const vNode =
    node instanceof AbstractVirtualNode ? node : getNodeFromTree(node);

  const { actualNode } = vNode;
  if (!isAriaTextbox(vNode)) {
    return '';
  }
  if (!actualNode || (actualNode && !isHiddenWithCSS(actualNode))) {
    return visibleVirtual(vNode, true);
  } else {
    return actualNode.textContent;
  }
}

/**
 * Calculate value of an element with role=combobox or role=listbox
 *
 * @param {VirtualNode} element The VirtualNode instance whose value we want
 * @param {Object} context The VirtualNode instance whose value we want
 * @property {Element} startNode First node in accessible name computation
 * @property {String[]} unsupported List of roles where value computation is unsupported
 * @property {Bool} debug Enable logging for formControlValue
 * @return {string} The calculated value
 */
function ariaListboxValue(node, context) {
  const vNode =
    node instanceof AbstractVirtualNode ? node : getNodeFromTree(node);

  if (!isAriaListbox(vNode)) {
    return '';
  }

  const selected = getOwnedVirtual(vNode).filter(
    owned =>
      getRole(owned) === 'option' && owned.attr('aria-selected') === 'true'
  );

  if (selected.length === 0) {
    return '';
  }
  // Note: Even with aria-multiselectable, only the first value will be used
  // in the accessible name. This isn't spec'ed out, but seems to be how all
  // browser behave.
  return accessibleTextVirtual(selected[0], context);
}

/**
 * Calculate value of an element with role=combobox or role=listbox
 *
 * @param {VirtualNode} element The VirtualNode instance whose value we want
 * @param {Object} context The VirtualNode instance whose value we want
 * @property {Element} startNode First node in accessible name computation
 * @property {String[]} unsupported List of roles where value computation is unsupported
 * @property {Bool} debug Enable logging for formControlValue
 * @return {string} The calculated value
 */
function ariaComboboxValue(node, context) {
  const vNode =
    node instanceof AbstractVirtualNode ? node : getNodeFromTree(node);

  // For combobox, find the first owned listbox:
  if (!isAriaCombobox(vNode)) {
    return '';
  }
  const listbox = getOwnedVirtual(vNode).filter(
    elm => getRole(elm) === 'listbox'
  )[0];

  return listbox ? ariaListboxValue(listbox, context) : '';
}

/**
 * Calculate value of an element with range-type role
 *
 * @param {VirtualNode|Node} element The VirtualNode instance whose value we want
 * @return {string} The calculated value
 */
function ariaRangeValue(node) {
  const vNode =
    node instanceof AbstractVirtualNode ? node : getNodeFromTree(node);

  if (!isAriaRange(vNode) || !vNode.hasAttr('aria-valuenow')) {
    return '';
  }
  // Validate the number, if not, return 0.
  // Chrome 70 typecasts this, Firefox 62 does not
  const valueNow = +vNode.attr('aria-valuenow');
  return !isNaN(valueNow) ? String(valueNow) : '0';
}

export default formControlValue;
