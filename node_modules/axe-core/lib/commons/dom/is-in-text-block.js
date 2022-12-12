import getComposedParent from './get-composed-parent';
import sanitize from '../text/sanitize';
import { getNodeFromTree } from '../../core/utils';

function walkDomNode(node, functor) {
  if (functor(node.actualNode) !== false) {
    node.children.forEach(child => walkDomNode(child, functor));
  }
}

const blockLike = [
  'block',
  'list-item',
  'table',
  'flex',
  'grid',
  'inline-block'
];
function isBlock(elm) {
  var display = window.getComputedStyle(elm).getPropertyValue('display');
  return blockLike.includes(display) || display.substr(0, 6) === 'table-';
}

function getBlockParent(node) {
  // Find the closest parent
  let parentBlock = getComposedParent(node);
  while (parentBlock && !isBlock(parentBlock)) {
    parentBlock = getComposedParent(parentBlock);
  }

  return getNodeFromTree(parentBlock);
}

/**
 * Determines if an element is within a text block
 * @param  {Element} node [description]
 * @return {Boolean}      [description]
 */
function isInTextBlock(node) {
  if (isBlock(node)) {
    // Ignore if the link is a block
    return false;
  }

  // Find all the text part of the parent block not in a link, and all the text in a link
  const virtualParent = getBlockParent(node);
  let parentText = '';
  let linkText = '';
  let inBrBlock = 0;

  // We want to ignore hidden text, and if br / hr is used, only use the section of the parent
  // that has the link we're looking at
  walkDomNode(virtualParent, currNode => {
    // We're already passed it, skip everything else
    if (inBrBlock === 2) {
      return false;
    }

    if (currNode.nodeType === 3) {
      // Add the text to the parent
      parentText += currNode.nodeValue;
    }
    // Ignore any node that's not an element (or text as above)
    if (currNode.nodeType !== 1) {
      return;
    }

    var nodeName = (currNode.nodeName || '').toUpperCase();
    // BR and HR elements break the line
    if (['BR', 'HR'].includes(nodeName)) {
      if (inBrBlock === 0) {
        parentText = '';
        linkText = '';
      } else {
        inBrBlock = 2;
      }

      // Don't walk nodes with content not displayed on screen.
    } else if (
      currNode.style.display === 'none' ||
      currNode.style.overflow === 'hidden' ||
      !['', null, 'none'].includes(currNode.style.float) ||
      !['', null, 'relative'].includes(currNode.style.position)
    ) {
      return false;

      // Don't walk links, we're only interested in what's not in them.
    } else if (
      (nodeName === 'A' && currNode.href) ||
      (currNode.getAttribute('role') || '').toLowerCase() === 'link'
    ) {
      if (currNode === node) {
        inBrBlock = 1;
      }
      // Grab all the text from this element, but don't walk down it's children
      linkText += currNode.textContent;
      return false;
    }
  });

  parentText = sanitize(parentText);
  linkText = sanitize(linkText);

  return parentText.length > linkText.length;
}

export default isInTextBlock;
