/**
 * Returns the reference node of the reference object, or the reference object itself.
 * @method
 * @memberof Popper.Utils
 * @param {Element|Object} reference - the reference element (the popper will be relative to this)
 * @returns {Element} parent
 */
export default function getReferenceNode(reference) {
  return reference && reference.referenceNode ? reference.referenceNode : reference;
}
