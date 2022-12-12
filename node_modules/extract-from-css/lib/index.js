
var cssParser = require('css');

var extractClassesFromRules = require('./extract-classes-from-rules');
var extractIdsFromRules = require('./extract-ids-from-rules');

/**
 * Extract the class names from the selectors found
 * in the specified code. Class order is not guaranteed.
 * @param  {string} code the CSS code to parse
 * @return {Array.<string>} the list of class names
 */
function extractClasses(code) {
  var ast = cssParser.parse(code);
  return extractClassesFromRules(ast.stylesheet.rules);
}

/**
 * Extract the ids from the selectors found
 * in the specified code. Id order is not guaranteed.
 * @param  {string} code the CSS code to parse
 * @return {Array.<string>} the list of ids
 */
function extractIds(code) {
  var ast = cssParser.parse(code);
  return extractIdsFromRules(ast.stylesheet.rules);
}

var extractMethods = {
  extractClassesFromRules: extractClassesFromRules,
  extractIdsFromRules: extractIdsFromRules
};

function capitalize(string) {
  return string.charAt(0).toUpperCase() + string.slice(1).toLowerCase();
}

/**
 * Extract the specified features from a given code
 * @param  {string[]} features
 * @param  {string} code
 * @return {Object.<string, string[]>} For each feature, a list of matches
 */
function extract(features, code) {
  var ast = cssParser.parse(code);
  var rules = ast.stylesheet.rules;
  var method, methodName, feature;
  var result = {};
  var i = 0;
  while (!!(feature = features[i++])) {
    methodName = 'extract' + capitalize(feature) + 'FromRules';
    method = extractMethods[methodName];
    if (method) {
      result[feature] = method(rules);
    } else {
      throw new Error('Unsupported feature ' + feature);
    }
  }
  return result;
}

extract.extractClasses = extractClasses;
extract.extractIds = extractIds;

module.exports = extract;
