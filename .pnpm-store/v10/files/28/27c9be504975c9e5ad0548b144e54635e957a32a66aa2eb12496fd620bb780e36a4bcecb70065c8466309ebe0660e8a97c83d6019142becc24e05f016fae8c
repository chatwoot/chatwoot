/**
 * @author ItMaga
 * See LICENSE file in root directory for full license.
 */
'use strict'

const utils = require('../utils')

const DEFAULT_OPTIONS = {
  defineProps: 'props',
  defineEmits: 'emit',
  defineSlots: 'slots',
  useSlots: 'slots',
  useAttrs: 'attrs'
}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description: 'require a certain macro variable name',
      categories: undefined,
      url: 'https://eslint.vuejs.org/rules/require-macro-variable-name.html'
    },
    fixable: null,
    hasSuggestions: true,
    schema: [
      {
        type: 'object',
        properties: {
          defineProps: {
            type: 'string',
            default: DEFAULT_OPTIONS.defineProps
          },
          defineEmits: {
            type: 'string',
            default: DEFAULT_OPTIONS.defineEmits
          },
          defineSlots: {
            type: 'string',
            default: DEFAULT_OPTIONS.defineSlots
          },
          useSlots: {
            type: 'string',
            default: DEFAULT_OPTIONS.useSlots
          },
          useAttrs: {
            type: 'string',
            default: DEFAULT_OPTIONS.useAttrs
          }
        },
        additionalProperties: false
      }
    ],
    messages: {
      requireName:
        'The variable name of "{{macroName}}" must be "{{variableName}}".',
      changeName: 'Change the variable name to "{{variableName}}".'
    }
  },
  /** @param {RuleContext} context */
  create(context) {
    const options = context.options[0] || DEFAULT_OPTIONS
    const relevantMacros = new Set([
      ...Object.keys(DEFAULT_OPTIONS),
      'withDefaults'
    ])

    return utils.defineScriptSetupVisitor(context, {
      VariableDeclarator(node) {
        if (
          node.init &&
          node.init.type === 'CallExpression' &&
          node.init.callee.type === 'Identifier' &&
          relevantMacros.has(node.init.callee.name)
        ) {
          const macroName =
            node.init.callee.name === 'withDefaults'
              ? 'defineProps'
              : node.init.callee.name

          if (
            node.id.type === 'Identifier' &&
            node.id.name !== options[macroName]
          ) {
            context.report({
              node: node.id,
              loc: node.id.loc,
              messageId: 'requireName',
              data: {
                macroName,
                variableName: options[macroName]
              },
              suggest: [
                {
                  messageId: 'changeName',
                  data: {
                    variableName: options[macroName]
                  },
                  fix(fixer) {
                    return fixer.replaceText(node.id, options[macroName])
                  }
                }
              ]
            })
          }
        }
      }
    })
  }
}
