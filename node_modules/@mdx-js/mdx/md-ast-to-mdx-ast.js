const visit = require('unist-util-visit')
const {isComment, getCommentContents} = require('@mdx-js/util')

module.exports = _options => tree => {
  visit(tree, 'jsx', node => {
    if (isComment(node.value)) {
      node.type = 'comment'
      node.value = getCommentContents(node.value)
    }
  })

  return tree
}
