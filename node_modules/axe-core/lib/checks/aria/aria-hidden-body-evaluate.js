/**
 * Check that the element does not have the `aria-hidden` attribute.
 *
 * @memberof checks
 * @return {Boolean} True if the `aria-hidden` attribute is not present. False otherwise.
 */
function ariaHiddenBodyEvaluate(node, options, virtualNode) {
  return virtualNode.attr('aria-hidden') !== 'true';
}

export default ariaHiddenBodyEvaluate;
