'use strict'

var remove = require('unist-util-remove')

module.exports = squeeze

var whiteSpaceOnly = /^\s*$/

function squeeze(tree) {
  return remove(tree, {cascade: false}, isEmptyParagraph)
}

// Whether paragraph is empty or composed only of whitespace.
function isEmptyParagraph(node) {
  return node.type === 'paragraph' && node.children.every(isEmptyText)
}

function isEmptyText(node) {
  return node.type === 'text' && whiteSpaceOnly.test(node.value)
}
