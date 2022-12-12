/* global document */
import { getAccessibleRefs } from '../commons/aria';
import { findUpVirtual, visuallyOverlaps, getRootNode } from '../commons/dom';
import { visibleVirtual, removeUnicode, sanitize } from '../commons/text';
import { isDisabled } from '../commons/forms';
import { getNodeFromTree, querySelectorAll, tokenList } from '../core/utils';

function colorContrastMatches(node, virtualNode) {
  const { nodeName, type: inputType } = virtualNode.props;

  // Don't test options, color contrast doesn't work well on these
  if (nodeName === 'option') {
    return false;
  }
  // Don't test empty select elements
  if (nodeName === 'select' && !node.options.length) {
    return false;
  }

  // some input types don't have text, so the rule shouldn't be applied
  const nonTextInput = [
    'hidden',
    'range',
    'color',
    'checkbox',
    'radio',
    'image'
  ];
  if (nodeName === 'input' && nonTextInput.includes(inputType)) {
    return false;
  }

  if (isDisabled(virtualNode)) {
    return false;
  }

  // form elements that don't have direct child text nodes need to check that
  // the text indent has not been changed and moved the text away from the
  // control
  const formElements = ['input', 'select', 'textarea'];
  if (formElements.includes(nodeName)) {
    const style = window.getComputedStyle(node);
    const textIndent = parseInt(style.getPropertyValue('text-indent'), 10);

    if (textIndent) {
      // since we can't get the actual bounding rect of the text node, we'll
      // use the current nodes bounding rect and adjust by the text-indent to
      // see if it still overlaps the node
      let rect = node.getBoundingClientRect();
      rect = {
        top: rect.top,
        bottom: rect.bottom,
        left: rect.left + textIndent,
        right: rect.right + textIndent
      };

      if (!visuallyOverlaps(rect, node)) {
        return false;
      }
    }
    // Match all form fields, regardless of if they have text
    return true;
  }
  const nodeParentLabel = findUpVirtual(virtualNode, 'label');
  if (nodeName === 'label' || nodeParentLabel) {
    const labelNode = nodeParentLabel || node;
    const labelVirtual = nodeParentLabel
      ? getNodeFromTree(nodeParentLabel)
      : virtualNode;

    // explicit label of disabled control
    if (labelNode.htmlFor) {
      const doc = getRootNode(labelNode);
      const explicitControl = doc.getElementById(labelNode.htmlFor);
      const explicitControlVirtual =
        explicitControl && getNodeFromTree(explicitControl);

      if (explicitControlVirtual && isDisabled(explicitControlVirtual)) {
        return false;
      }
    }

    // implicit label of disabled control
    const query =
      'input:not(' +
      '[type="hidden"],' +
      '[type="image"],' +
      '[type="button"],' +
      '[type="submit"],' +
      '[type="reset"]' +
      '), select, textarea';
    const implicitControl = querySelectorAll(labelVirtual, query)[0];

    if (implicitControl && isDisabled(implicitControl)) {
      return false;
    }
  }

  const ariaLabelledbyControls = [];
  let ancestorNode = virtualNode;
  while (ancestorNode) {
    // Find any ancestor (including itself) that is used with aria-labelledby
    if (ancestorNode.props.id) {
      const virtualControls = getAccessibleRefs(ancestorNode)
        .filter(control => {
          return tokenList(
            control.getAttribute('aria-labelledby') || ''
          ).includes(ancestorNode.props.id);
        })
        .map(control => getNodeFromTree(control));

      ariaLabelledbyControls.push(...virtualControls);
    }
    ancestorNode = ancestorNode.parent;
  }

  if (
    ariaLabelledbyControls.length > 0 &&
    ariaLabelledbyControls.every(isDisabled)
  ) {
    return false;
  }

  const visibleText = visibleVirtual(virtualNode, false, true);
  const removeUnicodeOptions = {
    emoji: true,
    nonBmp: false,
    punctuations: true
  };
  if (!visibleText || !removeUnicode(visibleText, removeUnicodeOptions)) {
    return false;
  }

  const range = document.createRange();
  const childNodes = virtualNode.children;
  for (let index = 0; index < childNodes.length; index++) {
    const child = childNodes[index];
    if (
      child.actualNode.nodeType === 3 &&
      sanitize(child.actualNode.nodeValue) !== ''
    ) {
      range.selectNodeContents(child.actualNode);
    }
  }

  const rects = range.getClientRects();
  for (let index = 0; index < rects.length; index++) {
    //check to see if the rectangle impinges
    if (visuallyOverlaps(rects[index], node)) {
      return true;
    }
  }
  return false;
}

export default colorContrastMatches;
