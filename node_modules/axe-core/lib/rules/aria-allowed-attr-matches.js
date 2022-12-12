function ariaAllowedAttrMatches(node, virtualNode) {
  const aria = /^aria-/;
  const attrs = virtualNode.attrNames;
  if (attrs.length) {
    for (let i = 0, l = attrs.length; i < l; i++) {
      if (aria.test(attrs[i])) {
        return true;
      }
    }
  }

  return false;
}

export default ariaAllowedAttrMatches;
