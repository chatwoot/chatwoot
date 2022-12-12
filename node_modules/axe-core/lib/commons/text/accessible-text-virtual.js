import arialabelledbyText from '../aria/arialabelledby-text';
import arialabelText from '../aria/arialabel-text';
import nativeTextAlternative from './native-text-alternative';
import formControlValue from './form-control-value';
import subtreeText from './subtree-text';
import titleText from './title-text';
import sanitize from './sanitize';
import isVisible from '../dom/is-visible';

/**
 * Finds virtual node and calls accessibleTextVirtual()
 * IMPORTANT: This method requires the composed tree at axe._tree
 *
 * @param {HTMLElement} element The HTMLElement
 * @param {Object} context
 * @property {Bool} inControlContext
 * @property {Bool} inLabelledByContext
 * @return {string}
 */
function accessibleTextVirtual(virtualNode, context = {}) {
  const { actualNode } = virtualNode;
  context = prepareContext(virtualNode, context);

  // Step 2A, check visibility
  if (shouldIgnoreHidden(virtualNode, context)) {
    return '';
  }

  const computationSteps = [
    arialabelledbyText, // Step 2B.1
    arialabelText, // Step 2C
    nativeTextAlternative, // Step 2D
    formControlValue, // Step 2E
    subtreeText, // Step 2F + Step 2H
    textNodeValue, // Step 2G (order with 2H does not matter)
    titleText // Step 2I
  ];

  // Find the first step that returns a non-empty string
  const accName = computationSteps.reduce((accName, step) => {
    if (context.startNode === virtualNode) {
      accName = sanitize(accName);
    }

    if (accName !== '') {
      // yes, whitespace only a11y names halt the algorithm
      return accName;
    }
    return step(virtualNode, context);
  }, '');

  if (context.debug) {
    axe.log(accName || '{empty-value}', actualNode, context);
  }
  return accName;
}

/**
 * Return the nodeValue of a node
 * @param {VirtualNode} element
 * @return {String} nodeValue value
 */
function textNodeValue(virtualNode) {
  if (virtualNode.props.nodeType !== 3) {
    return '';
  }
  return virtualNode.props.nodeValue;
}

/**
 * Check if the
 * @param {VirtualNode} element
 * @param {Object} context
 * @property {VirtualNode[]} processed
 * @return {Boolean}
 */
function shouldIgnoreHidden({ actualNode }, context) {
  if (!actualNode) {
    return false;
  }

  if (
    // If the parent isn't ignored, the text node should not be either
    actualNode.nodeType !== 1 ||
    // If the target of aria-labelledby is hidden, ignore all descendents
    context.includeHidden
  ) {
    return false;
  }

  return !isVisible(actualNode, true);
}

/**
 * Apply defaults to the context
 * @param {VirtualNode} element
 * @param {Object} context
 * @return {Object} context object with defaults applied
 */
function prepareContext(virtualNode, context) {
  const { actualNode } = virtualNode;
  if (!context.startNode) {
    context = { startNode: virtualNode, ...context };
  }

  if (!actualNode) {
    return context;
  }

  /**
   * When `aria-labelledby` directly references a `hidden` element
   * the element needs to be included in the accessible name.
   *
   * When a descendent of the `aria-labelledby` reference is `hidden`
   * the element should not be included in the accessible name.
   *
   * This is done by setting `includeHidden` for the `aria-labelledby` reference.
   */
  if (
    actualNode.nodeType === 1 &&
    context.inLabelledByContext &&
    context.includeHidden === undefined
  ) {
    context = {
      includeHidden: !isVisible(actualNode, true),
      ...context
    };
  }
  return context;
}

/**
 * Check if the node is processed with this context before
 * @param {VirtualNode} element
 * @param {Object} context
 * @property {VirtualNode[]} processed
 * @return {Boolean}
 */
accessibleTextVirtual.alreadyProcessed = function alreadyProcessed(
  virtualnode,
  context
) {
  context.processed = context.processed || [];
  if (context.processed.includes(virtualnode)) {
    return true;
  }

  context.processed.push(virtualnode);
  return false;
};

export default accessibleTextVirtual;
