import standards from '../../standards';
import matchesFn from '../../commons/matches';

/**
 * Return the spec for an HTML element from the standards object. Since the spec is determined by the node and what attributes it has, a node is required.
 * @param {VirtualNode} vNode The VirtualNode to get the spec for.
 * @return {Object} The standard spec object
 */
function getElementSpec(vNode) {
  const standard = standards.htmlElms[vNode.props.nodeName];

  // invalid element name (could be an svg or custom element name)
  if (!standard) {
    return {};
  }

  if (!standard.variant) {
    return standard;
  }

  // start with the information at the top level
  const { variant, ...spec } = standard;

  // loop through all variants (excluding default) finding anything
  // that matches
  for (const variantName in variant) {
    if (!variant.hasOwnProperty(variantName) || variantName === 'default') {
      continue;
    }

    const { matches, ...props } = variant[variantName];
    if (matchesFn(vNode, matches)) {
      for (const propName in props) {
        if (props.hasOwnProperty(propName)) {
          spec[propName] = props[propName];
        }
      }
    }
  }

  // apply defaults if properties were not found
  for (const propName in variant.default) {
    if (
      variant.default.hasOwnProperty(propName) &&
      typeof spec[propName] === 'undefined'
    ) {
      spec[propName] = variant.default[propName];
    }
  }

  return spec;
}

export default getElementSpec;
