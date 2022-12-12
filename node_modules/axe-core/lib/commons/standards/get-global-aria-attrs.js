import cache from '../../core/base/cache';
import standards from '../../standards';

/**
 * Return a list of global aria attributes.
 * @return {String[]} List of all global aria attributes
 */
function getGlobalAriaAttrs() {
  if (cache.get('globalAriaAttrs')) {
    return cache.get('globalAriaAttrs');
  }

  const globalAttrs = Object.keys(standards.ariaAttrs).filter(attrName => {
    return standards.ariaAttrs[attrName].global;
  });

  cache.set('globalAriaAttrs', globalAttrs);

  return globalAttrs;
}

export default getGlobalAriaAttrs;
