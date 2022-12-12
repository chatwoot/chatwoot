'use strict';

const fs = require('fs');
const mm = require('micromatch');

const matchers = [];

/**
 * Add glob patterns to ignore matched files and folders.
 * Creates glob patterns to approximate gitignore patterns.
 * @param {String} val - the glob or gitignore-style pattern to ignore
 * @see {@linkplain https://git-scm.com/docs/gitignore#_pattern_format}
 */
function addIgnorePattern(val) {
  if (val && typeof val === 'string' && val[0] !== '#') {
    let pattern = val;
    if (pattern.indexOf('/') === -1) {
      matchers.push('**/' + pattern);
    } else if (pattern[pattern.length-1] === '/') {
      matchers.push('**/' + pattern + '**');
      matchers.push(pattern + '**');
    }
    matchers.push(pattern);
  }
}

/**
 * Adds ignore patterns directly from function input
 * @param {String|Array<String>} input - the ignore patterns
 */
function addIgnoreFromInput(input) {
  let patterns = [];
  if (input) {
    patterns = patterns.concat(input);
  }
  patterns.forEach(addIgnorePattern);
}

/**
 * Adds ignore patterns by reading files
 * @param {String|Array<String>} input - the paths to the ignore config files
 */
function addIgnoreFromFile(input) {
  let lines = [];
  let files = [];
  if (input) {
    files = files.concat(input);
  }

  files.forEach(function(config) {
    const stats = fs.statSync(config);
    if (stats.isFile()) {
      const content = fs.readFileSync(config, 'utf8');
      lines = lines.concat(content.split(/\r?\n/));
    }
  });

  lines.forEach(addIgnorePattern);
}

function shouldIgnore(path) {
  const matched = matchers.length ? mm.isMatch(path, matchers, { dot:true }) : false;
  return matched;
}

exports.add = addIgnoreFromInput;
exports.addFromFile = addIgnoreFromFile;
exports.shouldIgnore = shouldIgnore;
