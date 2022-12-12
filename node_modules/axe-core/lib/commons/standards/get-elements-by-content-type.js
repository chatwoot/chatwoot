import standards from '../../standards';

/**
 * Return a list of html elements whose content type matches the provided value. Note: this will not work for 'interactive' content types as those depend on the element.
 * @param {String} type The desired content type
 * @return {String[]} List of all elements matching the type
 */
function getElementsByContentType(type) {
  return Object.keys(standards.htmlElms).filter(nodeName => {
    const elm = standards.htmlElms[nodeName];

    if (elm.contentTypes) {
      return elm.contentTypes.includes(type);
    }

    // some elements do not have content types
    if (!elm.variant) {
      return false;
    }

    if (elm.variant.default && elm.variant.default.contentTypes) {
      return elm.variant.default.contentTypes.includes(type);
    }

    // content type depends on a virtual node
    return false;
  });
}

export default getElementsByContentType;
