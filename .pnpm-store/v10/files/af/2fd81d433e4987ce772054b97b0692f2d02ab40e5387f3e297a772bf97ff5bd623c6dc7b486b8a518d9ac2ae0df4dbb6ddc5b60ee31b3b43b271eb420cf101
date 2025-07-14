/**
 * @author @neferqiqi
 * See LICENSE file in root directory for full license.
 */
'use strict'
const utils = require('../utils')
/**
 * @typedef {import('../utils').ComponentTypeProp} ComponentTypeProp
 * @typedef {import('../utils').ComponentArrayProp} ComponentArrayProp
 * @typedef {import('../utils').ComponentObjectProp} ComponentObjectProp
 * @typedef {import('../utils').ComponentUnknownProp} ComponentUnknownProp
 * @typedef {import('../utils').ComponentProp} ComponentProp
 */

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      description: 'enforce props with default values to be optional',
      categories: undefined,
      url: 'https://eslint.vuejs.org/rules/no-required-prop-with-default.html'
    },
    fixable: 'code',
    hasSuggestions: true,
    schema: [
      {
        type: 'object',
        properties: {
          autofix: {
            type: 'boolean'
          }
        },
        additionalProperties: false
      }
    ],
    messages: {
      requireOptional: `Prop "{{ key }}" should be optional.`,
      fixRequiredProp: `Change this prop to be optional.`
    }
  },
  /** @param {RuleContext} context */
  create(context) {
    let canAutoFix = false
    const option = context.options[0]
    if (option) {
      canAutoFix = option.autofix
    }

    /**
     * @param {ComponentArrayProp | ComponentObjectProp | ComponentUnknownProp | ComponentProp} prop
     * */
    const handleObjectProp = (prop) => {
      if (
        prop.type === 'object' &&
        prop.propName &&
        prop.value.type === 'ObjectExpression' &&
        utils.findProperty(prop.value, 'default')
      ) {
        const requiredProperty = utils.findProperty(prop.value, 'required')
        if (!requiredProperty) return
        const requiredNode = requiredProperty.value
        if (
          requiredNode &&
          requiredNode.type === 'Literal' &&
          !!requiredNode.value
        ) {
          context.report({
            node: prop.node,
            loc: prop.node.loc,
            data: {
              key: prop.propName
            },
            messageId: 'requireOptional',
            fix: canAutoFix
              ? (fixer) => fixer.replaceText(requiredNode, 'false')
              : null,
            suggest: canAutoFix
              ? null
              : [
                  {
                    messageId: 'fixRequiredProp',
                    fix: (fixer) => fixer.replaceText(requiredNode, 'false')
                  }
                ]
          })
        }
      }
    }

    return utils.compositingVisitors(
      utils.defineVueVisitor(context, {
        onVueObjectEnter(node) {
          utils.getComponentPropsFromOptions(node).map(handleObjectProp)
        }
      }),
      utils.defineScriptSetupVisitor(context, {
        onDefinePropsEnter(node, props) {
          if (!utils.hasWithDefaults(node)) {
            props.map(handleObjectProp)
            return
          }
          const withDefaultsProps = Object.keys(
            utils.getWithDefaultsPropExpressions(node)
          )
          const requiredProps = props.flatMap((item) =>
            item.type === 'type' && item.required ? [item] : []
          )

          for (const prop of requiredProps) {
            if (withDefaultsProps.includes(prop.propName)) {
              // skip setter & getter case
              if (
                prop.node.type === 'TSMethodSignature' &&
                (prop.node.kind === 'get' || prop.node.kind === 'set')
              ) {
                return
              }
              // skip computed
              if (prop.node.computed) {
                return
              }
              context.report({
                node: prop.node,
                loc: prop.node.loc,
                data: {
                  key: prop.propName
                },
                messageId: 'requireOptional',
                fix: canAutoFix
                  ? (fixer) => fixer.insertTextAfter(prop.key, '?')
                  : null,
                suggest: canAutoFix
                  ? null
                  : [
                      {
                        messageId: 'fixRequiredProp',
                        fix: (fixer) => fixer.insertTextAfter(prop.key, '?')
                      }
                    ]
              })
            }
          }
        }
      })
    )
  }
}
