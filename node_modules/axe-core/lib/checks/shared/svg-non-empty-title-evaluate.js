import visibleVirtual from '../../commons/text/visible-virtual';

function svgNonEmptyTitleEvaluate(node, options, virtualNode) {
  if (!virtualNode.children) {
    return undefined;
  }

  const titleNode = virtualNode.children.find(({ props }) => {
    return props.nodeName === 'title';
  });

  if (!titleNode) {
    this.data({
      messageKey: 'noTitle'
    });
    return false;
  }

  try {
    if (visibleVirtual(titleNode) === '') {
      this.data({
        messageKey: 'emptyTitle'
      });
      return false;
    }
  } catch (e) {
    return undefined;
  }

  return true;
}

export default svgNonEmptyTitleEvaluate;
