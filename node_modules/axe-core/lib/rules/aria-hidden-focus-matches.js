import { getComposedParent } from '../commons/dom';

/**
 * Only match the outer-most `aria-hidden=true` element
 * @param {HTMLElement} el the HTMLElement to verify
 * @return {Boolean}
 */
function shouldMatchElement(el) {
  if (!el) {
    return true;
  }
  if (el.getAttribute('aria-hidden') === 'true') {
    return false;
  }
  return shouldMatchElement(getComposedParent(el));
}

function ariaHiddenFocusMatches(node) {
  return shouldMatchElement(getComposedParent(node));
}

export default ariaHiddenFocusMatches;
