import titleText from './title-text';
import subtreeText from './subtree-text';
import labelText from './label-text';
import accessibleText from './accessible-text';

const defaultButtonValues = {
  submit: 'Submit',
  image: 'Submit',
  reset: 'Reset',
  button: '' // No default for "button"
};

const nativeTextMethods = {
  /**
   * Return the value of a DOM node
   * @param {VirtualNode} element
   * @return {String} value text
   */
  valueText: ({ actualNode }) => actualNode.value || '',

  /**
   * Return default value of a button
   * @param {VirtualNode} element
   * @return {String} default button text
   */
  buttonDefaultText: ({ actualNode }) =>
    defaultButtonValues[actualNode.type] || '',

  /**
   * Return caption text of an HTML table element
   * @param {VirtualNode} element
   * @param {Object} context
   * @return {String} caption text
   */
  tableCaptionText: descendantText.bind(null, 'caption'),

  /**
   * Return figcaption text of an HTML figure element
   * @param {VirtualNode} element
   * @param {Object} context
   * @return {String} figcaption text
   */
  figureText: descendantText.bind(null, 'figcaption'),

  /**
   * Return figcaption text of an HTML figure element
   * @param {VirtualNode} element
   * @param {Object} context
   * @return {String} figcaption text
   */
  svgTitleText: descendantText.bind(null, 'title'),

  /**
   * Return legend text of an HTML fieldset element
   * @param {VirtualNode} element
   * @param {Object} context
   * @return {String} legend text
   */
  fieldsetLegendText: descendantText.bind(null, 'legend'),

  /**
   * Return the alt text
   * @param {VirtualNode} element
   * @return {String} alt text
   */
  altText: attrText.bind(null, 'alt'),

  /**
   * Return summary text for an HTML table element
   * @param {VirtualNode} element
   * @return {String} summary text
   */
  tableSummaryText: attrText.bind(null, 'summary'),

  /**
   * Return the title text
   * @param {VirtualNode} element
   * @return {String} title text
   */
  titleText,

  /**
   * Return accessible text of the subtree
   * @param {VirtualNode} element
   * @param {Object} context
   * @return {String} Subtree text
   */
  subtreeText,

  /**
   * Return accessible text for an implicit and/or explicit HTML label element
   * @param {VirtualNode} element
   * @param {Object} context
   * @return {String} Label text
   */
  labelText,

  /**
   * Return a single space
   * @return {String} Returns ` `
   */
  singleSpace: function singleSpace() {
    return ' ';
  },

  /**
   * Return the placeholder text
   * @param {VirtualNode} element
   * @return {String} placeholder text
   */
  placeholderText: attrText.bind(null, 'placeholder')
};

function attrText(attr, vNode) {
  return vNode.attr(attr) || '';
}

/**
 * Get the accessible text of first matching node
 * IMPORTANT: This method does not look at the composed tree
 * @private
 */
function descendantText(nodeName, { actualNode }, context) {
  nodeName = nodeName.toLowerCase();
  // Prevent accidently getting the nested element, like:
  // fieldset > fielset > legend (1st fieldset has no legend)
  const nodeNames = [nodeName, actualNode.nodeName.toLowerCase()].join(',');
  const candidate = actualNode.querySelector(nodeNames);

  if (!candidate || candidate.nodeName.toLowerCase() !== nodeName) {
    return '';
  }
  return accessibleText(candidate, context);
}

export default nativeTextMethods;
