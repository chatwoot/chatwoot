import isFocusable from './is-focusable';
import isNativelyFocusable from './is-natively-focusable';

/**
 * Determines if an element is in the focus order, but would not be if its
 * tabindex were unspecified.
 * @method insertedIntoFocusOrder
 * @memberof axe.commons.dom
 * @instance
 * @param {HTMLElement} el The HTMLElement
 * @return {Boolean} True if the element is in the focus order but wouldn't be
 * if its tabindex were removed. Else, false.
 */
function insertedIntoFocusOrder(el) {
  const tabIndex = parseInt(el.getAttribute('tabindex'), 10);

  // an element that has an invalid tabindex will return 0 or -1 based on
  // if it is natively focusable or not, which will always be false for this
  // check as NaN is not > 1
  // @see https://www.w3.org/TR/html51/editing.html#the-tabindex-attribute
  return tabIndex > -1 && isFocusable(el) && !isNativelyFocusable(el);
}

export default insertedIntoFocusOrder;
