/**
 * Gets all Checks (or CheckResults) for a given Rule or RuleResult
 * @param {RuleResult|Rule} rule
 */
function getAllChecks(object) {
  var result = [];
  return result
    .concat(object.any || [])
    .concat(object.all || [])
    .concat(object.none || []);
}

export default getAllChecks;
