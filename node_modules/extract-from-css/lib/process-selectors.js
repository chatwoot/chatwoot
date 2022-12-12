
/**
 * Calls processFn for each selector found
 * at the given rule
 * @param  {Object} rule
 * @param  {Function} processFn
 */
function processRuleSelectors(rule, processFn) {
  var selectors = rule.selectors;
  for (var i = 0; i < selectors.length; i++) {
    processFn(selectors[i]);
  }
}

/**
 * Calls processFn for each selector found
 * at the given rules
 * @param  {Object[]} rules
 * @param  {Function} processFn
 */
function processSelectors(rules, processFn) {
  var rule;
  for (var i = 0; i < rules.length; i++) {
    rule = rules[i];
    if (rule.type === 'rule') {
      processRuleSelectors(rule, processFn);
    } else if (rule.rules) {
      // Add nested rules to the list
      // Will be checked after the current ones
      rules.push.apply(rules, rule.rules);
    }
  }
}

module.exports = processSelectors;
