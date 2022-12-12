
var cssHelpers = require('./css-helpers');
var selectorUniqueMatches = require('./selector-unique-matches');

/**
 * dot followed by an identifier
 * @type {RegExp}
 */
var rClassInSelector = new RegExp('\\.(' + cssHelpers.rIdentifier.source + ')',
  'gm');

/**
 * Extracts classes from CSS rules (as AST)
 * @param  {Object} rules
 * @return {string[]} list of ids in those rules
 */
function extractClassesFromRules(rules) {
  var classes = selectorUniqueMatches(rules, rClassInSelector);
  return classes.map(cssHelpers.unescapeIdentifier);
}

module.exports = extractClassesFromRules;
