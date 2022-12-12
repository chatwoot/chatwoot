import getGlobalAriaAttrs from '../../commons/standards/get-global-aria-attrs';

function hasGlobalAriaAttributeEvaluate(node, options, virtualNode) {
  const globalAttrs = getGlobalAriaAttrs().filter(attr =>
    virtualNode.hasAttr(attr)
  );
  this.data(globalAttrs);
  return globalAttrs.length > 0;
}

export default hasGlobalAriaAttributeEvaluate;
