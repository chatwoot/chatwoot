import isVisible from './is-visible';
import VirtualNode from '../../core/base/virtual-node/virtual-node';
import { getNodeFromTree, getScroll, isShadowRoot } from '../../core/utils';

// split the page cells to group elements by the position
const gridSize = 200; // arbitrary size, increase to reduce memory use (less cells) but increase time (more nodes per grid to check collision)

/**
 * Determine if node produces a stacking context.
 * References:
 * https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Positioning/Understanding_z_index/The_stacking_context
 * https://github.com/gwwar/z-context/blob/master/devtools/index.js
 * @param {VirtualNode} vNode
 * @return {Boolean}
 */
function isStackingContext(vNode, parentVNode) {
  const position = vNode.getComputedStylePropertyValue('position');
  const zIndex = vNode.getComputedStylePropertyValue('z-index');

  // the root element (HTML) is skipped since we always start with a
  // stacking order of [0]

  // position: fixed or sticky
  if (position === 'fixed' || position === 'sticky') {
    return true;
  }

  // positioned (absolutely or relatively) with a z-index value other than "auto",
  if (zIndex !== 'auto' && position !== 'static') {
    return true;
  }

  // elements with an opacity value less than 1.
  if (vNode.getComputedStylePropertyValue('opacity') !== '1') {
    return true;
  }

  // elements with a transform value other than "none"
  const transform =
    vNode.getComputedStylePropertyValue('-webkit-transform') ||
    vNode.getComputedStylePropertyValue('-ms-transform') ||
    vNode.getComputedStylePropertyValue('transform') ||
    'none';

  if (transform !== 'none') {
    return true;
  }

  // elements with a mix-blend-mode value other than "normal"
  const mixBlendMode = vNode.getComputedStylePropertyValue('mix-blend-mode');
  if (mixBlendMode && mixBlendMode !== 'normal') {
    return true;
  }

  // elements with a filter value other than "none"
  const filter = vNode.getComputedStylePropertyValue('filter');
  if (filter && filter !== 'none') {
    return true;
  }

  // elements with a perspective value other than "none"
  const perspective = vNode.getComputedStylePropertyValue('perspective');
  if (perspective && perspective !== 'none') {
    return true;
  }

  // element with a clip-path value other than "none"
  const clipPath = vNode.getComputedStylePropertyValue('clip-path');
  if (clipPath && clipPath !== 'none') {
    return true;
  }

  // element with a mask value other than "none"
  const mask =
    vNode.getComputedStylePropertyValue('-webkit-mask') ||
    vNode.getComputedStylePropertyValue('mask') ||
    'none';
  if (mask !== 'none') {
    return true;
  }

  // element with a mask-image value other than "none"
  const maskImage =
    vNode.getComputedStylePropertyValue('-webkit-mask-image') ||
    vNode.getComputedStylePropertyValue('mask-image') ||
    'none';
  if (maskImage !== 'none') {
    return true;
  }

  // element with a mask-border value other than "none"
  const maskBorder =
    vNode.getComputedStylePropertyValue('-webkit-mask-border') ||
    vNode.getComputedStylePropertyValue('mask-border') ||
    'none';
  if (maskBorder !== 'none') {
    return true;
  }

  // elements with isolation set to "isolate"
  if (vNode.getComputedStylePropertyValue('isolation') === 'isolate') {
    return true;
  }

  // transform or opacity in will-change even if you don't specify values for these attributes directly
  const willChange = vNode.getComputedStylePropertyValue('will-change');
  if (willChange === 'transform' || willChange === 'opacity') {
    return true;
  }

  // elements with -webkit-overflow-scrolling set to "touch"
  if (
    vNode.getComputedStylePropertyValue('-webkit-overflow-scrolling') ===
    'touch'
  ) {
    return true;
  }

  // element with a contain value of "layout" or "paint" or a composite value
  // that includes either of them (i.e. contain: strict, contain: content).
  const contain = vNode.getComputedStylePropertyValue('contain');
  if (['layout', 'paint', 'strict', 'content'].includes(contain)) {
    return true;
  }

  // a flex item or gird item with a z-index value other than "auto", that is the parent element display: flex|inline-flex|grid|inline-grid,
  if (zIndex !== 'auto' && parentVNode) {
    const parentDsiplay = parentVNode.getComputedStylePropertyValue('display');
    if (
      [
        'flex',
        'inline-flex',
        'inline flex',
        'grid',
        'inline-grid',
        'inline grid'
      ].includes(parentDsiplay)
    ) {
      return true;
    }
  }

  return false;
}

/**
 * Check if a node or one of it's parents is floated.
 * Floating position should be inherited from the parent tree
 * @see https://github.com/dequelabs/axe-core/issues/2222
 */
function isFloated(vNode) {
  if (!vNode) {
    return false;
  }

  if (vNode._isFloated !== undefined) {
    return vNode._isFloated;
  }

  const floatStyle = vNode.getComputedStylePropertyValue('float');

  if (floatStyle !== 'none') {
    vNode._isFloated = true;
    return true;
  }

  const floated = isFloated(vNode.parent);
  vNode._isFloated = floated;
  return floated;
}

/**
 * Return the index order of how to position this element. return nodes in non-positioned, floating, positioned order
 * References:
 * https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Positioning/Understanding_z_index/Stacking_without_z-index
 * https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Positioning/Understanding_z_index/Stacking_and_float
 * https://drafts.csswg.org/css2/visuren.html#layers
 * @param {VirtualNode} vNode
 * @return {Number}
 */
function getPositionOrder(vNode) {
  if (vNode.getComputedStylePropertyValue('position') === 'static') {
    // 5. the in-flow, inline-level, non-positioned descendants, including inline tables and inline blocks.
    if (
      vNode.getComputedStylePropertyValue('display').indexOf('inline') !== -1
    ) {
      return 2;
    }

    // 4. the non-positioned floats.
    if (isFloated(vNode)) {
      return 1;
    }

    // 3. the in-flow, non-inline-level, non-positioned descendants.
    return 0;
  }

  // 6. the child stacking contexts with stack level 0 and the positioned descendants with stack level 0.
  return 3;
}

/**
 * Visually sort nodes based on their stack order
 * References:
 * https://drafts.csswg.org/css2/visuren.html#layers
 * @param {VirtualNode}
 * @param {VirtualNode}
 */
function visuallySort(a, b) {
  /*eslint no-bitwise: 0 */
  for (let i = 0; i < a._stackingOrder.length; i++) {
    if (typeof b._stackingOrder[i] === 'undefined') {
      return -1;
    }

    // 7. the child stacking contexts with positive stack levels (least positive first).
    if (b._stackingOrder[i] > a._stackingOrder[i]) {
      return 1;
    }

    // 2. the child stacking contexts with negative stack levels (most negative first).
    if (b._stackingOrder[i] < a._stackingOrder[i]) {
      return -1;
    }
  }

  // nodes are the same stacking order
  let aNode = a.actualNode;
  let bNode = b.actualNode;

  // elements don't correctly calculate document position when comparing
  // across shadow boundaries, so we need to compare the position of a
  // shared host instead

  // elements have different hosts
  if (aNode.getRootNode && aNode.getRootNode() !== bNode.getRootNode()) {
    // keep track of all parent hosts and find the one both nodes share
    const boundaries = [];
    while (aNode) {
      boundaries.push({
        root: aNode.getRootNode(),
        node: aNode
      });
      aNode = aNode.getRootNode().host;
    }

    while (
      bNode &&
      !boundaries.find(boundary => boundary.root === bNode.getRootNode())
    ) {
      bNode = bNode.getRootNode().host;
    }

    // bNode is a node that shares a host with some part of the a parent
    // shadow tree, find the aNode that shares the same host as bNode
    aNode = boundaries.find(boundary => boundary.root === bNode.getRootNode())
      .node;

    // sort child of shadow to it's host node by finding which element is
    // the child of the host and sorting it before the host
    if (aNode === bNode) {
      return a.actualNode.getRootNode() !== aNode.getRootNode() ? -1 : 1;
    }
  }

  const {
    DOCUMENT_POSITION_FOLLOWING,
    DOCUMENT_POSITION_CONTAINS,
    DOCUMENT_POSITION_CONTAINED_BY
  } = window.Node;

  const docPosition = aNode.compareDocumentPosition(bNode);
  const DOMOrder = docPosition & DOCUMENT_POSITION_FOLLOWING ? 1 : -1;
  const isDescendant =
    docPosition & DOCUMENT_POSITION_CONTAINS ||
    docPosition & DOCUMENT_POSITION_CONTAINED_BY;
  const aPosition = getPositionOrder(a);
  const bPosition = getPositionOrder(b);

  // a child of a positioned element should also be on top of the parent
  if (aPosition === bPosition || isDescendant) {
    return DOMOrder;
  }

  return bPosition - aPosition;
}

/**
 * Determine the stacking order of an element. The stacking order is an array of
 * zIndex values for each stacking context parent.
 * @param {VirtualNode}
 * @return {Number[]}
 */
function getStackingOrder(vNode, parentVNode) {
  const stackingOrder = parentVNode._stackingOrder.slice();
  const zIndex = vNode.getComputedStylePropertyValue('z-index');
  if (zIndex !== 'auto') {
    stackingOrder[stackingOrder.length - 1] = parseInt(zIndex);
  }
  if (isStackingContext(vNode, parentVNode)) {
    stackingOrder.push(0);
  }

  return stackingOrder;
}

/**
 * Return the parent node that is a scroll region.
 * @param {VirtualNode}
 * @return {VirtualNode|null}
 */
function findScrollRegionParent(vNode, parentVNode) {
  let scrollRegionParent = null;
  const checkedNodes = [vNode];

  while (parentVNode) {
    if (parentVNode._scrollRegionParent) {
      scrollRegionParent = parentVNode._scrollRegionParent;
      break;
    }

    if (getScroll(parentVNode.actualNode)) {
      scrollRegionParent = parentVNode;
      break;
    }

    checkedNodes.push(parentVNode);
    parentVNode = getNodeFromTree(
      parentVNode.actualNode.parentElement || parentVNode.actualNode.parentNode
    );
  }

  // cache result of parent scroll region so we don't have to look up the entire
  // tree again for a child node
  checkedNodes.forEach(
    vNode => (vNode._scrollRegionParent = scrollRegionParent)
  );
  return scrollRegionParent;
}

/**
 * Add a node to every cell of the grid it intersects with.
 * @param {Grid}
 * @param {VirtualNode}
 */
function addNodeToGrid(grid, vNode) {
  // save a reference to where this element is in the grid so we
  // can find it even if it's in a subgrid
  vNode._grid = grid;

  vNode.clientRects.forEach(rect => {
    const x = rect.left;
    const y = rect.top;

    // "| 0" is a faster way to do Math.floor
    // @see https://jsperf.com/math-floor-vs-math-round-vs-parseint/152
    const startRow = (y / gridSize) | 0;
    const startCol = (x / gridSize) | 0;
    const endRow = ((y + rect.height) / gridSize) | 0;
    const endCol = ((x + rect.width) / gridSize) | 0;

    for (let row = startRow; row <= endRow; row++) {
      grid.cells[row] = grid.cells[row] || [];

      for (let col = startCol; col <= endCol; col++) {
        grid.cells[row][col] = grid.cells[row][col] || [];

        if (!grid.cells[row][col].includes(vNode)) {
          grid.cells[row][col].push(vNode);
        }
      }
    }
  });
}

/**
 * Setup the 2d grid and add every element to it, even elements not
 * included in the flat tree
 */
export function createGrid(
  root = document.body,
  rootGrid = {
    container: null,
    cells: []
  },
  parentVNode = null
) {
  // by not starting at the htmlElement we don't have to pass a custom
  // filter function into the treeWalker to filter out head elements,
  // which would be called for every node
  if (!parentVNode) {
    let vNode = getNodeFromTree(document.documentElement);
    if (!vNode) {
      vNode = new VirtualNode(document.documentElement);
    }

    vNode._stackingOrder = [0];
    addNodeToGrid(rootGrid, vNode);

    if (getScroll(vNode.actualNode)) {
      const subGrid = {
        container: vNode,
        cells: []
      };
      vNode._subGrid = subGrid;
    }
  }

  // IE11 requires the first 3 parameters
  // @see https://developer.mozilla.org/en-US/docs/Web/API/Document/createTreeWalker
  const treeWalker = document.createTreeWalker(
    root,
    window.NodeFilter.SHOW_ELEMENT,
    null,
    false
  );
  let node = parentVNode ? treeWalker.nextNode() : treeWalker.currentNode;
  while (node) {
    let vNode = getNodeFromTree(node);

    // an svg in IE11 does not have a parentElement but instead has a
    // parentNode. but parentNode could be a shadow root so we need to
    // verity it's in the tree first
    if (node.parentElement) {
      parentVNode = getNodeFromTree(node.parentElement);
    } else if (node.parentNode && getNodeFromTree(node.parentNode)) {
      parentVNode = getNodeFromTree(node.parentNode);
    }

    if (!vNode) {
      vNode = new axe.VirtualNode(node, parentVNode);
    }

    vNode._stackingOrder = getStackingOrder(vNode, parentVNode);

    const scrollRegionParent = findScrollRegionParent(vNode, parentVNode);
    const grid = scrollRegionParent ? scrollRegionParent._subGrid : rootGrid;

    if (getScroll(vNode.actualNode)) {
      const subGrid = {
        container: vNode,
        cells: []
      };
      vNode._subGrid = subGrid;
    }

    // filter out any elements with 0 width or height
    // (we don't do this before so we can calculate stacking context
    // of parents with 0 width/height)
    const rect = vNode.boundingClientRect;
    if (rect.width !== 0 && rect.height !== 0 && isVisible(node)) {
      addNodeToGrid(grid, vNode);
    }

    // add shadow root elements to the grid
    if (isShadowRoot(node)) {
      createGrid(node.shadowRoot, grid, vNode);
    }

    node = treeWalker.nextNode();
  }
}

export function getRectStack(grid, rect, recursed = false) {
  // use center point of rect
  const x = rect.left + rect.width / 2;
  const y = rect.top + rect.height / 2;

  // NOTE: there is a very rare edge case in Chrome vs Firefox that can
  // return different results of `document.elementsFromPoint`. If the center
  // point of the element is <1px outside of another elements bounding rect,
  // Chrome appears to round the number up and return the element while Firefox
  // keeps the number as is and won't return the element. In this case, we
  // went with pixel perfect collision rather than rounding
  const row = (y / gridSize) | 0;
  const col = (x / gridSize) | 0;
  let stack = grid.cells[row][col].filter(gridCellNode => {
    return gridCellNode.clientRects.find(clientRect => {
      const rectX = clientRect.left;
      const rectY = clientRect.top;

      // perform an AABB (axis-aligned bounding box) collision check for the
      // point inside the rect
      return (
        x <= rectX + clientRect.width &&
        x >= rectX &&
        y <= rectY + clientRect.height &&
        y >= rectY
      );
    });
  });

  const gridContainer = grid.container;
  if (gridContainer) {
    stack = getRectStack(
      gridContainer._grid,
      gridContainer.boundingClientRect,
      true
    ).concat(stack);
  }

  if (!recursed) {
    stack = stack
      .sort(visuallySort)
      .map(vNode => vNode.actualNode)
      // always make sure html is the last element
      .concat(document.documentElement)
      // remove duplicates caused by adding client rects of the same node
      .filter((node, index, array) => array.indexOf(node) === index);
  }

  return stack;
}
