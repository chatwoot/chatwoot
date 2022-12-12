function avoidInlineSpacingEvaluate(node, options) {
  const overriddenProperties = options.cssProperties.filter(property => {
    if (node.style.getPropertyPriority(property) === `important`) {
      return property;
    }
  });

  if (overriddenProperties.length > 0) {
    this.data(overriddenProperties);
    return false;
  }

  return true;
}

export default avoidInlineSpacingEvaluate;
