function metaRefreshEvaluate(node, options, virtualNode) {
  var content = virtualNode.attr('content') || '',
    parsedParams = content.split(/[;,]/);

  return content === '' || parsedParams[0] === '0';
}

export default metaRefreshEvaluate;
