/**
 * @author Yosuke Ota
 * See LICENSE file in root directory for full license.
 */
'use strict'

const utils = require('../utils')
const regexp = require('../utils/regexp')

/**
 * @typedef {import('../utils').ComponentProp} ComponentProp
 */

/**
 * @typedef {object} ParsedOption
 * @property { (name: string) => boolean } test
 * @property {string|undefined} [message]
 * @property {string|undefined} [suggest]
 */

/**
 * @param {string} str
 * @returns {(str: string) => boolean}
 */
function buildMatcher(str) {
  if (regexp.isRegExp(str)) {
    const re = regexp.toRegExp(str)
    return (s) => {
      re.lastIndex = 0
      return re.test(s)
    }
  }
  return (s) => s === str
}
/**
 * @param {string|{name:string, message?: string, suggest?:string}} option
 * @returns {ParsedOption}
 */
function parseOption(option) {
  if (typeof option === 'string') {
    const matcher = buildMatcher(option)
    return {
      test(name) {
        return matcher(name)
      }
    }
  }
  const parsed = parseOption(option.name)
  parsed.message = option.message
  parsed.suggest = option.suggest
  return parsed
}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description: 'disallow specific props',
      categories: undefined,
      url: 'https://eslint.vuejs.org/rules/no-restricted-props.html'
    },
    fixable: null,
    hasSuggestions: true,
    schema: {
      type: 'array',
      items: {
        oneOf: [
          { type: ['string'] },
          {
            type: 'object',
            properties: {
              name: { type: 'string' },
              message: { type: 'string', minLength: 1 },
              suggest: { type: 'string' }
            },
            required: ['name'],
            additionalProperties: false
          }
        ]
      },
      uniqueItems: true,
      minItems: 0
    },

    messages: {
      // eslint-disable-next-line eslint-plugin/report-message-format
      restrictedProp: '{{message}}',
      instead: 'Instead, change to `{{suggest}}`.'
    }
  },
  /** @param {RuleContext} context */
  create(context) {
    /** @type {ParsedOption[]} */
    const options = context.options.map(parseOption)

    /**
     * @param {ComponentProp[]} props
     * @param { { [key: string]: Property | undefined } } [withDefaultsProps]
     */
    function processProps(props, withDefaultsProps) {
      for (const prop of props) {
        if (!prop.propName) {
          continue
        }

        for (const option of options) {
          if (option.test(prop.propName)) {
            const message =
              option.message ||
              `Using \`${prop.propName}\` props is not allowed.`
            context.report({
              node: prop.type === 'infer-type' ? prop.node : prop.key,
              messageId: 'restrictedProp',
              data: { message },
              suggest:
                prop.type === 'infer-type'
                  ? null
                  : createSuggest(
                      prop.key,
                      option,
                      withDefaultsProps && withDefaultsProps[prop.propName]
                    )
            })
            break
          }
        }
      }
    }
    return utils.compositingVisitors(
      utils.defineScriptSetupVisitor(context, {
        onDefinePropsEnter(node, props) {
          processProps(props, utils.getWithDefaultsProps(node))
        }
      }),
      utils.defineVueVisitor(context, {
        onVueObjectEnter(node) {
          processProps(utils.getComponentPropsFromOptions(node))
        }
      })
    )
  }
}

/**
 * @param {Expression} node
 * @param {ParsedOption} option
 * @param {Property} [withDefault]
 * @returns {Rule.SuggestionReportDescriptor[]}
 */
function createSuggest(node, option, withDefault) {
  if (!option.suggest) {
    return []
  }

  /** @type {string} */
  let replaceText
  if (node.type === 'Literal' || node.type === 'TemplateLiteral') {
    replaceText = JSON.stringify(option.suggest)
  } else if (node.type === 'Identifier') {
    replaceText = /^[a-z]\w*$/iu.test(option.suggest)
      ? option.suggest
      : JSON.stringify(option.suggest)
  } else {
    return []
  }

  return [
    {
      fix(fixer) {
        const fixes = [fixer.replaceText(node, replaceText)]
        if (withDefault) {
          if (withDefault.shorthand) {
            fixes.push(
              fixer.insertTextBefore(withDefault.value, `${replaceText}:`)
            )
          } else {
            fixes.push(fixer.replaceText(withDefault.key, replaceText))
          }
        }
        return fixes.sort((a, b) => a.range[0] - b.range[0])
      },
      messageId: 'instead',
      data: { suggest: option.suggest }
    }
  ]
}
