
var processSelectors = require('./process-selectors');

/**
 * Returns the matches of the first capture group in the given regular
 * expression in the specified rules (AST), without repetition
 *
 * @example
 * var rules = getRulesFromCode('[href] { background: red }');
 * var regexp = /\[(\w+)\]/g; // Notice the parenthesis!
 * selectorUniqueMatches(rules, regexp);
 * //> ['href']
 *
 * @param  {Object[]} rules
 * @param  {RegExp} regexp
 * @return {string[]}
 */
function selectorUniqueMatches(rules, regexp) {
  var resultSet = {};
  processSelectors(rules, function(selector) {
    var match;
    while (!!(match = regexp.exec(selector))) {
      resultSet[match[1]] = true;
    }
  });
  return Object.keys(resultSet);
}

module.exports = selectorUniqueMatches;
