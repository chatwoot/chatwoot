import findUpVirtual from './find-up-virtual';
import { getNodeFromTree } from '../../core/utils';

/**
 * Find the virtual node and call dom.fundUpVirtual
 *
 * **WARNING:** this should be used sparingly, as it's not even close to being performant
 * @method findUp
 * @memberof axe.commons.dom
 * @instance
 * @deprecated use axe.utils.closest
 * @param {HTMLElement} element The starting HTMLElement
 * @param {String} target The selector for the HTMLElement
 * @return {HTMLElement|null} Either the matching HTMLElement or `null` if there was no match
 */
function findUp(element, target) {
  return findUpVirtual(getNodeFromTree(element), target);
}

export default findUp;
