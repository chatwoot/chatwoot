import getComposedParent from './get-composed-parent';
import { getNodeFromTree } from '../../core/utils';

/**
 * Determine whether an element is hidden based on css
 * @method isHiddenWithCSS
 * @memberof axe.commons.dom
 * @instance
 * @param {HTMLElement} el The HTML Element
 * @param {Boolean} descendentVisibilityValue (Optional) immediate descendant visibility value used for recursive computation
 * @return {Boolean} the element's hidden status
 */
function isHiddenWithCSS(el, descendentVisibilityValue) {
  const vNode = getNodeFromTree(el);

  if (!vNode) {
    return _isHiddenWithCSS(el, descendentVisibilityValue);
  }

  if (vNode._isHiddenWithCSS === void 0) {
    vNode._isHiddenWithCSS = _isHiddenWithCSS(el, descendentVisibilityValue);
  }

  return vNode._isHiddenWithCSS;
}

function _isHiddenWithCSS(el, descendentVisibilityValue) {
  if (el.nodeType === 9) {
    // 9 === Node.DOCUMENT
    return false;
  }

  if (el.nodeType === 11) {
    // 11 === Node.DOCUMENT_FRAGMENT_NODE
    el = el.host; // swap to host node
  }

  if (['STYLE', 'SCRIPT'].includes(el.nodeName.toUpperCase())) {
    return false;
  }

  const style = window.getComputedStyle(el, null);
  if (!style) {
    throw new Error('Style does not exist for the given element.');
  }

  const displayValue = style.getPropertyValue('display');
  if (displayValue === 'none') {
    return true;
  }

  const HIDDEN_VISIBILITY_VALUES = ['hidden', 'collapse'];
  const visibilityValue = style.getPropertyValue('visibility');
  if (
    HIDDEN_VISIBILITY_VALUES.includes(visibilityValue) &&
    !descendentVisibilityValue
  ) {
    return true;
  }

  if (
    HIDDEN_VISIBILITY_VALUES.includes(visibilityValue) &&
    descendentVisibilityValue &&
    HIDDEN_VISIBILITY_VALUES.includes(descendentVisibilityValue)
  ) {
    return true;
  }

  const parent = getComposedParent(el);
  if (parent && !HIDDEN_VISIBILITY_VALUES.includes(visibilityValue)) {
    return isHiddenWithCSS(parent, visibilityValue);
  }
  return false;
}

export default isHiddenWithCSS;
