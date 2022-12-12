
var cssHelpers = require('./css-helpers');
var selectorUniqueMatches = require('./selector-unique-matches');

/**
 * number sign followed by an identifier
 * @type {RegExp}
 */
var rIdInSelector = new RegExp('#(' + cssHelpers.rIdentifier.source + ')',
  'gm');

/**
 * Extracts ids from CSS rules (as AST)
 * @param  {Object} rules
 * @return {string[]} list of ids in those rules
 */
function extractIdsFromRules(rules) {
  var ids = selectorUniqueMatches(rules, rIdInSelector);
  return ids.map(cssHelpers.unescapeIdentifier);
}

module.exports = extractIdsFromRules;
