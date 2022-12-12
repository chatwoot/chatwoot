const visualRoles = [
  'checkbox',
  'img',
  'radio',
  'range',
  'slider',
  'spinbutton',
  'textbox'
];

/**
 * Check if an element is an inherently visual element
 * @method isVisualContent
 * @memberof axe.commons.dom
 * @instance
 * @param  {Element} element The element to check
 * @return {Boolean}
 */
function isVisualContent(element) {
  /*eslint indent: 0*/
  const role = element.getAttribute('role');
  if (role) {
    return visualRoles.indexOf(role) !== -1;
  }

  switch (element.nodeName.toUpperCase()) {
    case 'IMG':
    case 'IFRAME':
    case 'OBJECT':
    case 'VIDEO':
    case 'AUDIO':
    case 'CANVAS':
    case 'SVG':
    case 'MATH':
    case 'BUTTON':
    case 'SELECT':
    case 'TEXTAREA':
    case 'KEYGEN':
    case 'PROGRESS':
    case 'METER':
      return true;
    case 'INPUT':
      return element.type !== 'hidden';
    default:
      return false;
  }
}

export default isVisualContent;
