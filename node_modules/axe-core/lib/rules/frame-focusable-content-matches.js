function frameFocusableContentMatches(node, virtualNode, context) {
  return (
    !context.initiator &&
    !context.focusable &&
    context.boundingClientRect.width * context.boundingClientRect.height > 1
  );
}

export default frameFocusableContentMatches;
