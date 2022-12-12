import visibleVirtual from './visible-virtual';
import { getNodeFromTree } from '../../core/utils';

/**
 * Finds virtual node and calls visibleVirtual()
 * IMPORTANT: This method requires the composed tree at axe._tree
 * @param  {Element} element
 * @param  {Boolean} screenReader When provided, will evaluate visibility from the perspective of a screen reader
 * @param  {Boolean} noRecursing When False, the result will contain text from the element and it's children.
 * When True, the result will only contain text from the element
 * @return {String}
 */
function visible(element, screenReader, noRecursing) {
  element = getNodeFromTree(element);
  return visibleVirtual(element, screenReader, noRecursing);
}

export default visible;
