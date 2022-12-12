import matches from '../../commons/matches';

function matchesDefinitionEvaluate(_, options, virtualNode) {
  return matches(virtualNode, options.matcher);
}

export default matchesDefinitionEvaluate;
