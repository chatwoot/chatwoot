"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getStorybookConfiguration = getStorybookConfiguration;

/*
 * Lifted from chromatic-cli
 *
 * This is not exactly clever but it works most of the time
 * we receive the full text of the npm script, and we look if we can find the cli flag
 */
function getStorybookConfiguration(storybookScript, shortName, longName) {
  if (!storybookScript) {
    return null;
  }

  var parts = storybookScript.split(/[\s='"]+/);
  var index = parts.indexOf(longName);

  if (index === -1) {
    index = parts.indexOf(shortName);
  }

  if (index === -1) {
    return null;
  }

  return parts[index + 1];
}