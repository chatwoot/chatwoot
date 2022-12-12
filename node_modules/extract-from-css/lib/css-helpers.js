
/**
 * multiple ocurrences of:
 *   - alphabetical letter, underscore or dash, or
 *   - non-ascii character, or
 *   - escaped character
 * @type {RegExp}
 */
var rIdentifier =
  /(?:[A-Za-z0-9_-]|[^\0-\237]|\\(?:[^A-Fa-f0-9]|[A-Fa-f0-9]{1,6} ?))+/;

/**
 * backslash followed by a non-hexadecimal letter or
 * a 1 to 6 digit hexadecimal number followed by an optional white space
 * @type {RegExp}
 */
var rEscapedCharacter = /\\([^A-Fa-f0-9]|[A-Fa-f0-9]{1,6} ?)/g;

/**
 * Unescapes a single character
 * @param  {string} escapedCharacter escaped character starting with a backslash
 * @return {string} unescaped character
 */
function unescapeCharacter(escapedCharacter) {
  var escapeValue = escapedCharacter.substr(1);
  var numberValue = parseInt(escapeValue, 16);
  if (isNaN(numberValue)) {
    return escapeValue;
  }

  return String.fromCharCode(numberValue);
}

/**
 * Unescapes all escaped characters in the given identifier
 * @param  {string} identifier identifier with possible escaped characters
 * @return {string} unescaped identifier
 */
function unescapeIdentifier(identifier) {
  return identifier.replace(rEscapedCharacter, unescapeCharacter);
}

module.exports = {
  rIdentifier: rIdentifier,
  rEscapedCharacter: rEscapedCharacter,
  unescapeIdentifier: unescapeIdentifier,
  unescapeCharacter: unescapeCharacter
};
