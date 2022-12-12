/**
 * Reduce an array of elements to only those that are below a 'floating' element.
 * @method reduceToElementsBelowFloating
 * @memberof axe.commons.dom
 * @instance
 * @param {Array} elements
 * @param {Element} targetNode
 * @returns {Array}
 */
function reduceToElementsBelowFloating(elements, targetNode) {
  const floatingPositions = ['fixed', 'sticky'];
  let finalElements = [];
  let targetFound = false;

  // Filter out elements that are temporarily floating above the target
  for (let index = 0; index < elements.length; ++index) {
    const currentNode = elements[index];
    if (currentNode === targetNode) {
      targetFound = true;
    }

    const style = window.getComputedStyle(currentNode);

    if (!targetFound && floatingPositions.indexOf(style.position) !== -1) {
      //Target was not found yet, so it must be under this floating thing (and will not always be under it)
      finalElements = [];
      continue;
    }

    finalElements.push(currentNode);
  }

  return finalElements;
}

export default reduceToElementsBelowFloating;
