/**
 * @fileoverview disallow the use of reserved names in component definitions
 * @author Jake Hassel <https://github.com/shadskii>
 */
'use strict'

const utils = require('../utils')
const casing = require('../utils/casing')

const htmlElements = require('../utils/html-elements.json')
const deprecatedHtmlElements = require('../utils/deprecated-html-elements.json')
const svgElements = require('../utils/svg-elements.json')

const kebabCaseElements = [
  'annotation-xml',
  'color-profile',
  'font-face',
  'font-face-src',
  'font-face-uri',
  'font-face-format',
  'font-face-name',
  'missing-glyph'
]

const isLowercase = (word) => /^[a-z]*$/.test(word)
const capitalizeFirstLetter = (word) => word[0].toUpperCase() + word.substring(1, word.length)

const RESERVED_NAMES = new Set(
  [
    ...kebabCaseElements,
    ...kebabCaseElements.map(casing.pascalCase),
    ...htmlElements,
    ...htmlElements.map(capitalizeFirstLetter),
    ...deprecatedHtmlElements,
    ...deprecatedHtmlElements.map(capitalizeFirstLetter),
    ...svgElements,
    ...svgElements.filter(isLowercase).map(capitalizeFirstLetter)
  ])

// ------------------------------------------------------------------------------
// Rule Definition
// ------------------------------------------------------------------------------

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description: 'disallow the use of reserved names in component definitions',
      category: undefined, // 'essential'
      url: 'https://eslint.vuejs.org/rules/no-reserved-component-names.html'
    },
    fixable: null,
    schema: []
  },

  create (context) {
    function canVerify (node) {
      return node.type === 'Literal' || (
        node.type === 'TemplateLiteral' &&
        node.expressions.length === 0 &&
        node.quasis.length === 1
      )
    }

    function reportIfInvalid (node) {
      let name
      if (node.type === 'TemplateLiteral') {
        const quasis = node.quasis[0]
        name = quasis.value.cooked
      } else {
        name = node.value
      }
      if (RESERVED_NAMES.has(name)) {
        report(node, name)
      }
    }

    function report (node, name) {
      context.report({
        node: node,
        message: 'Name "{{name}}" is reserved.',
        data: {
          name: name
        }
      })
    }

    return Object.assign({},
      utils.executeOnCallVueComponent(context, (node) => {
        if (node.arguments.length === 2) {
          const argument = node.arguments[0]

          if (canVerify(argument)) {
            reportIfInvalid(argument)
          }
        }
      }),
      utils.executeOnVue(context, (obj) => {
        // Report if a component has been registered locally with a reserved name.
        utils.getRegisteredComponents(obj)
          .filter(({ name }) => RESERVED_NAMES.has(name))
          .forEach(({ node, name }) => report(node, name))

        const node = obj.properties
          .find(item => (
            item.type === 'Property' &&
            item.key.name === 'name' &&
            canVerify(item.value)
          ))

        if (!node) return
        reportIfInvalid(node.value)
      })
    )
  }
}
