/**
 * @fileoverview Report used components
 * @author Michał Sajnóg
 */
'use strict'

// ------------------------------------------------------------------------------
// Requirements
// ------------------------------------------------------------------------------

const utils = require('../utils')
const casing = require('../utils/casing')

// ------------------------------------------------------------------------------
// Rule Definition
// ------------------------------------------------------------------------------

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description: 'disallow registering components that are not used inside templates',
      category: 'essential',
      url: 'https://eslint.vuejs.org/rules/no-unused-components.html'
    },
    fixable: null,
    schema: [{
      type: 'object',
      properties: {
        ignoreWhenBindingPresent: {
          type: 'boolean'
        }
      },
      additionalProperties: false
    }]
  },

  create (context) {
    const options = context.options[0] || {}
    const ignoreWhenBindingPresent = options.ignoreWhenBindingPresent !== undefined ? options.ignoreWhenBindingPresent : true
    const usedComponents = new Set()
    let registeredComponents = []
    let ignoreReporting = false
    let templateLocation

    return utils.defineTemplateBodyVisitor(context, {
      VElement (node) {
        if (
          (!utils.isHtmlElementNode(node) && !utils.isSvgElementNode(node)) ||
          utils.isHtmlWellKnownElementName(node.rawName) ||
          utils.isSvgWellKnownElementName(node.rawName)
        ) {
          return
        }

        usedComponents.add(node.rawName)
      },
      "VAttribute[directive=true][key.name.name='bind'][key.argument.name='is']" (node) {
        if (
          !node.value ||  // `<component :is>`
          node.value.type !== 'VExpressionContainer' ||
          !node.value.expression  // `<component :is="">`
        ) return

        if (node.value.expression.type === 'Literal') {
          usedComponents.add(node.value.expression.value)
        } else if (ignoreWhenBindingPresent) {
          ignoreReporting = true
        }
      },
      "VAttribute[directive=false][key.name='is']" (node) {
        usedComponents.add(node.value.value)
      },
      "VElement[name='template']" (rootNode) {
        templateLocation = templateLocation || rootNode.loc.start
      },
      "VElement[name='template']:exit" (rootNode) {
        if (
          rootNode.loc.start !== templateLocation ||
          ignoreReporting ||
          utils.hasAttribute(rootNode, 'src')
        ) return

        registeredComponents
          .filter(({ name }) => {
            // If the component name is PascalCase or camelCase
            // it can be used in various of ways inside template,
            // like "theComponent", "The-component" etc.
            // but except snake_case
            if (casing.pascalCase(name) === name || casing.camelCase(name) === name) {
              return ![...usedComponents].some(n => {
                return n.indexOf('_') === -1 && (name === casing.pascalCase(n) || casing.camelCase(n) === name)
              })
            } else {
              // In any other case the used component name must exactly match
              // the registered name
              return !usedComponents.has(name)
            }
          })
          .forEach(({ node, name }) => context.report({
            node,
            message: 'The "{{name}}" component has been registered but not used.',
            data: {
              name
            }
          }))
      }
    }, utils.executeOnVue(context, (obj) => {
      registeredComponents = utils.getRegisteredComponents(obj)
    }))
  }
}
