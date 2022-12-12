import standards from '../../standards';

/**
 * Check if an aria- attribute name is valid
 * @method validateAttr
 * @memberof axe.commons.aria
 * @instance
 * @param  {String} att The attribute name
 * @return {Boolean}
 */
function validateAttr(att) {
  const attrDefinition = standards.ariaAttrs[att];
  return !!attrDefinition;
}

export default validateAttr;
