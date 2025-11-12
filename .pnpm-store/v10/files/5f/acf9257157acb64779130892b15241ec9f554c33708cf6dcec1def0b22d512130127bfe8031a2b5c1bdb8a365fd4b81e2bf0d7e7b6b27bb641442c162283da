/**
 * @fileoverview disallow adding multiple root nodes to the template
 * @author Przemyslaw Falowski (@przemkow)
 */
'use strict'

const utils = require('../utils')

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      description: 'disallow adding multiple root nodes to the template',
      categories: ['vue2-essential'],
      url: 'https://eslint.vuejs.org/rules/no-multiple-template-root.html'
    },
    fixable: null,
    schema: [],
    messages: {
      multipleRoot: 'The template root requires exactly one element.',
      textRoot: 'The template root requires an element rather than texts.',
      disallowedElement: "The template root disallows '<{{name}}>' elements.",
      disallowedDirective: "The template root disallows 'v-for' directives."
    }
  },
  /**
   * @param {RuleContext} context - The rule context.
   * @returns {RuleListener} AST event handlers.
   */
  create(context) {
    const sourceCode = context.getSourceCode()

    return {
      Program(program) {
        const element = program.templateBody
        if (element == null) {
          return
        }

        const rootElements = []
        let extraText = null
        let extraElement = null
        let vIf = false
        for (const child of element.children) {
          if (child.type === 'VElement') {
            if (rootElements.length === 0) {
              rootElements.push(child)
              vIf = utils.hasDirective(child, 'if')
            } else if (vIf && utils.hasDirective(child, 'else-if')) {
              rootElements.push(child)
            } else if (vIf && utils.hasDirective(child, 'else')) {
              rootElements.push(child)
              vIf = false
            } else {
              extraElement = child
            }
          } else if (sourceCode.getText(child).trim() !== '') {
            extraText = child
          }
        }

        if (extraText != null) {
          context.report({
            node: extraText,
            loc: extraText.loc,
            messageId: 'textRoot'
          })
        } else if (extraElement == null) {
          for (const element of rootElements) {
            const tag = element.startTag
            const name = element.name

            if (name === 'template' || name === 'slot') {
              context.report({
                node: tag,
                loc: tag.loc,
                messageId: 'disallowedElement',
                data: { name }
              })
            }
            if (utils.hasDirective(element, 'for')) {
              context.report({
                node: tag,
                loc: tag.loc,
                messageId: 'disallowedDirective'
              })
            }
          }
        } else {
          context.report({
            node: extraElement,
            loc: extraElement.loc,
            messageId: 'multipleRoot'
          })
        }
      }
    }
  }
}
