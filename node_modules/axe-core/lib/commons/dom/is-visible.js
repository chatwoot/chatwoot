import getRootNode from './get-root-node';
import isOffscreen from './is-offscreen';
import findUp from './find-up';
import {
  getScroll,
  getNodeFromTree,
  querySelectorAll,
  escapeSelector
} from '../../core/utils';

const clipRegex = /rect\s*\(([0-9]+)px,?\s*([0-9]+)px,?\s*([0-9]+)px,?\s*([0-9]+)px\s*\)/;
const clipPathRegex = /(\w+)\((\d+)/;

/**
 * Determines if an element is hidden with a clip or clip-path technique
 * @method isClipped
 * @memberof axe.commons.dom
 * @private
 * @param  {CSSStyleDeclaration} style Computed style
 * @return {Boolean}
 */
function isClipped(style) {
  const matchesClip = style.getPropertyValue('clip').match(clipRegex);
  const matchesClipPath = style
    .getPropertyValue('clip-path')
    .match(clipPathRegex);
  if (matchesClip && matchesClip.length === 5) {
    return (
      matchesClip[3] - matchesClip[1] <= 0 &&
      matchesClip[2] - matchesClip[4] <= 0
    );
  }
  if (matchesClipPath) {
    const type = matchesClipPath[1];
    const value = parseInt(matchesClipPath[2], 10);

    switch (type) {
      case 'inset':
        return value >= 50;
      case 'circle':
        return value === 0;
      default:
    }
  }

  return false;
}

/**
 * Check `AREA` element is visible
 * - validate if it is a child of `map`
 * - ensure `map` is referred by `img` using the `usemap` attribute
 * @param {Element} areaEl `AREA` element
 * @retruns {Boolean}
 */
function isAreaVisible(el, screenReader, recursed) {
  /**
   * Note:
   * - Verified that `map` element cannot refer to `area` elements across different document trees
   * - Verified that `map` element does not get affected by altering `display` property
   */
  const mapEl = findUp(el, 'map');
  if (!mapEl) {
    return false;
  }

  const mapElName = mapEl.getAttribute('name');
  if (!mapElName) {
    return false;
  }

  /**
   * `map` element has to be in light DOM
   */
  const mapElRootNode = getRootNode(el);
  if (!mapElRootNode || mapElRootNode.nodeType !== 9) {
    return false;
  }

  const refs = querySelectorAll(
    // TODO: es-module-_tree
    axe._tree,
    `img[usemap="#${escapeSelector(mapElName)}"]`
  );
  if (!refs || !refs.length) {
    return false;
  }

  return refs.some(({ actualNode }) =>
    isVisible(actualNode, screenReader, recursed)
  );
}

/**
 * Determine whether an element is visible
 * @method isVisible
 * @memberof axe.commons.dom
 * @instance
 * @param {HTMLElement} el The HTMLElement
 * @param {Boolean} screenReader When provided, will evaluate visibility from the perspective of a screen reader
 * @param {Boolean} recursed
 * @return {Boolean} The element's visibilty status
 */
function isVisible(el, screenReader, recursed) {
  if (!el) {
    throw new TypeError(
      'Cannot determine if element is visible for non-DOM nodes'
    );
  }

  const vNode = getNodeFromTree(el);
  const cacheName = '_isVisible' + (screenReader ? 'ScreenReader' : '');

  // 9 === Node.DOCUMENT
  if (el.nodeType === 9) {
    return true;
  }

  // 11 === Node.DOCUMENT_FRAGMENT_NODE
  if (el.nodeType === 11) {
    el = el.host; // grab the host Node
  }

  if (vNode && typeof vNode[cacheName] !== 'undefined') {
    return vNode[cacheName];
  }

  const style = window.getComputedStyle(el, null);
  if (style === null) {
    return false;
  }

  const nodeName = el.nodeName.toUpperCase();

  /**
   * check visibility of `AREA`
   * Note:
   * Firefox's user-agent always sets `AREA` element to `display:none`
   * hence excluding the edge case, for visibility computation
   */
  if (nodeName === 'AREA') {
    return isAreaVisible(el, screenReader, recursed);
  }

  // always hidden
  if (
    style.getPropertyValue('display') === 'none' ||
    ['STYLE', 'SCRIPT', 'NOSCRIPT', 'TEMPLATE'].includes(nodeName)
  ) {
    return false;
  }

  // hidden from screen readers
  if (screenReader && el.getAttribute('aria-hidden') === 'true') {
    return false;
  }

  // hidden from visual users
  if (
    !screenReader &&
    (isClipped(style) ||
      style.getPropertyValue('opacity') === '0' ||
      (getScroll(el) && parseInt(style.getPropertyValue('height')) === 0))
  ) {
    return false;
  }

  // visibility is only accurate on the first element and
  // position does not matter if it was already calculated
  if (
    !recursed &&
    (style.getPropertyValue('visibility') === 'hidden' ||
      (!screenReader && isOffscreen(el)))
  ) {
    return false;
  }

  const parent = el.assignedSlot ? el.assignedSlot : el.parentNode;
  let visible = false;
  if (parent) {
    visible = isVisible(parent, screenReader, true);
  }

  if (vNode) {
    vNode[cacheName] = visible;
  }

  return visible;
}

export default isVisible;
