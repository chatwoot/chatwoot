import aggregateNodeResults from './aggregate-node-results';

/**
 * Process rule results, grouping them by outcome
 * @param ruleResult {object}
 * @return {object}
 */
function finalizeRuleResult(ruleResult) {
  // we don't use getRule so that this code does not throw but returns
  // the results
  const rule = axe._audit.rules.find(rule => rule.id === ruleResult.id);
  if (rule && rule.impact) {
    ruleResult.nodes.forEach(node => {
      ['any', 'all', 'none'].forEach(checkType => {
        (node[checkType] || []).forEach(checkResult => {
          checkResult.impact = rule.impact;
        });
      });
    });
  }

  Object.assign(ruleResult, aggregateNodeResults(ruleResult.nodes));
  delete ruleResult.nodes;

  return ruleResult;
}

export default finalizeRuleResult;
