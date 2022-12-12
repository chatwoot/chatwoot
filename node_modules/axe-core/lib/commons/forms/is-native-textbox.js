import { getNodeFromTree } from '../../core/utils';
import AbstractVirtuaNode from '../../core/base/virtual-node/abstract-virtual-node';

const nonTextInputTypes = [
  'button',
  'checkbox',
  'color',
  'file',
  'hidden',
  'image',
  'password',
  'radio',
  'reset',
  'submit'
];

/**
 * Determines if an element is a native textbox element
 * @method isNativeTextbox
 * @memberof axe.commons.forms
 * @param {VirtualNode|Element} node Node to determine if textbox
 * @returns {Bool}
 */
function isNativeTextbox(node) {
  node = node instanceof AbstractVirtuaNode ? node : getNodeFromTree(node);
  const nodeName = node.props.nodeName;
  return (
    nodeName === 'textarea' ||
    (nodeName === 'input' &&
      !nonTextInputTypes.includes((node.attr('type') || '').toLowerCase()))
  );
}

export default isNativeTextbox;
