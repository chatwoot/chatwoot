import isVisible from './is-visible';
import getViewportSize from './get-viewport-size';
import cache from '../../core/base/cache';
import { querySelectorAllFilter } from '../../core/utils';

/**
 * Determines if there is a modal currently open.
 * @method isModalOpen
 * @memberof axe.commons.dom
 * @instance
 * @return {Boolean|undefined} True if we know (or our best guess) that a modal is open, undefined if we can't tell (doesn't mean there isn't one open)
 */
function isModalOpen(options) {
  options = options || {};
  const modalPercent = options.modalPercent || 0.75;

  // there is no "definitive" way to code a modal so detecting when one is open
  // is a bit of a guess. a modal won't always be accessible, so we can't rely
  // on the `role` attribute, and relying on a class name as a convention is
  // unreliable. we also cannot rely on the body/html not scrolling.
  //
  // because of this, we will look for two different types of modals:
  // "definitely a modal" and "could be a modal."
  //
  // "definitely a modal" is any visible element that is coded to be a modal
  // by using one of the following criteria:
  //
  // - has the attribute `role=dialog`
  // - has the attribute `aria-modal=true`
  // - is the dialog element
  //
  // "could be a modal" is a visible element that takes up more than 75% of
  // the screen (though typically full width/height) and is the top-most element
  // in the viewport. since we aren't sure if it is or is not a modal this is
  // just our best guess of being one based on convention.

  if (cache.get('isModalOpen')) {
    return cache.get('isModalOpen');
  }

  const definiteModals = querySelectorAllFilter(
    // TODO: es-module-_tree
    axe._tree[0],
    'dialog, [role=dialog], [aria-modal=true]',
    vNode => isVisible(vNode.actualNode)
  );

  if (definiteModals.length) {
    cache.set('isModalOpen', true);
    return true;
  }

  // to find a "could be a modal" we will take the element stack from each of
  // four corners and one from the middle of the viewport (total of 5). if each
  // stack contains an element whose width/height is >= 75% of the screen, we
  // found a "could be a modal"
  const viewport = getViewportSize(window);
  const percentWidth = viewport.width * modalPercent;
  const percentHeight = viewport.height * modalPercent;
  const x = (viewport.width - percentWidth) / 2;
  const y = (viewport.height - percentHeight) / 2;

  const points = [
    // top-left corner
    { x, y },
    // top-right corner
    { x: viewport.width - x, y },
    // center
    { x: viewport.width / 2, y: viewport.height / 2 },
    // bottom-left corner
    { x, y: viewport.height - y },
    // bottom-right corner
    { x: viewport.width - x, y: viewport.height - y }
  ];

  const stacks = points.map(point => {
    return Array.from(document.elementsFromPoint(point.x, point.y));
  });

  for (let i = 0; i < stacks.length; i++) {
    // a modal isn't guaranteed to be the top most element so we'll have to
    // find the first element in the stack that meets the modal criteria
    // and make sure it's in the other stacks
    const modalElement = stacks[i].find(elm => {
      const style = window.getComputedStyle(elm);
      return (
        parseInt(style.width, 10) >= percentWidth &&
        parseInt(style.height, 10) >= percentHeight &&
        style.getPropertyValue('pointer-events') !== 'none' &&
        (style.position === 'absolute' || style.position === 'fixed')
      );
    });

    if (modalElement && stacks.every(stack => stack.includes(modalElement))) {
      cache.set('isModalOpen', true);
      return true;
    }
  }

  cache.set('isModalOpen', undefined);
  return undefined;
}

export default isModalOpen;
