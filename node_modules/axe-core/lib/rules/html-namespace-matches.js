import svgNamespaceMatches from './svg-namespace-matches';

function htmlNamespaceMatches(node, virtualNode) {
  return !svgNamespaceMatches(node, virtualNode);
}

export default htmlNamespaceMatches;
