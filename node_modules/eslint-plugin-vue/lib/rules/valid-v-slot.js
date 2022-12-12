/**
 * @author Toru Nagashima
 * See LICENSE file in root directory for full license.
 */
'use strict'

const utils = require('../utils')

/**
 * Get all `v-slot` directives on a given element.
 * @param {VElement} node The VElement node to check.
 * @returns {VAttribute[]} The array of `v-slot` directives.
 */
function getSlotDirectivesOnElement (node) {
  return node.startTag.attributes.filter(attribute =>
    attribute.directive &&
    attribute.key.name.name === 'slot'
  )
}

/**
 * Get all `v-slot` directives on the children of a given element.
 * @param {VElement} node The VElement node to check.
 * @returns {VAttribute[][]}
 * The array of the group of `v-slot` directives.
 * The group bundles `v-slot` directives of element sequence which is connected
 * by `v-if`/`v-else-if`/`v-else`.
 */
function getSlotDirectivesOnChildren (node) {
  return node.children
    .reduce(({ groups, vIf }, childNode) => {
      if (childNode.type === 'VElement') {
        let connected
        if (utils.hasDirective(childNode, 'if')) {
          connected = false
          vIf = true
        } else if (utils.hasDirective(childNode, 'else-if')) {
          connected = vIf
          vIf = true
        } else if (utils.hasDirective(childNode, 'else')) {
          connected = vIf
          vIf = false
        } else {
          connected = false
          vIf = false
        }

        if (connected) {
          groups[groups.length - 1].push(childNode)
        } else {
          groups.push([childNode])
        }
      } else if (childNode.type !== 'VText' || childNode.value.trim() !== '') {
        vIf = false
      }
      return { groups, vIf }
    }, { groups: [], vIf: false })
    .groups
    .map(group =>
      group
        .map(childElement =>
          childElement.name === 'template'
            ? utils.getDirective(childElement, 'slot')
            : null
        )
        .filter(Boolean)
    )
    .filter(group => group.length >= 1)
}

/**
 * Get the normalized name of a given `v-slot` directive node.
 * @param {VAttribute} node The `v-slot` directive node.
 * @returns {string} The normalized name.
 */
function getNormalizedName (node, sourceCode) {
  return node.key.argument == null ? 'default' : sourceCode.getText(node.key.argument)
}

/**
 * Get all `v-slot` directives which are distributed to the same slot as a given `v-slot` directive node.
 * @param {VAttribute[][]} vSlotGroups The result of `getAllNamedSlotElements()`.
 * @param {VElement} currentVSlot The current `v-slot` directive node.
 * @returns {VAttribute[][]} The array of the group of `v-slot` directives.
 */
function filterSameSlot (vSlotGroups, currentVSlot, sourceCode) {
  const currentName = getNormalizedName(currentVSlot, sourceCode)
  return vSlotGroups
    .map(vSlots =>
      vSlots.filter(vSlot => getNormalizedName(vSlot, sourceCode) === currentName)
    )
    .filter(slots => slots.length >= 1)
}

/**
 * Check whether a given argument node is using an iteration variable that the element defined.
 * @param {VExpressionContainer|VIdentifier|null} argument The argument node to check.
 * @param {VElement} element The element node which has the argument.
 * @returns {boolean} `true` if the argument node is using the iteration variable.
 */
function isUsingIterationVar (argument, element) {
  if (argument && argument.type === 'VExpressionContainer') {
    for (const { variable } of argument.references) {
      if (
        variable != null &&
        variable.kind === 'v-for' &&
        variable.id.range[0] > element.startTag.range[0] &&
        variable.id.range[1] < element.startTag.range[1]
      ) {
        return true
      }
    }
  }
  return false
}

/**
 * Check whether a given argument node is using an scope variable that the directive defined.
 * @param {VAttribute} vSlot The `v-slot` directive to check.
 * @returns {boolean} `true` if that argument node is using a scope variable the directive defined.
 */
function isUsingScopeVar (vSlot) {
  const argument = vSlot.key.argument
  const value = vSlot.value

  if (argument && value && argument.type === 'VExpressionContainer') {
    for (const { variable } of argument.references) {
      if (
        variable != null &&
        variable.kind === 'scope' &&
        variable.id.range[0] > value.range[0] &&
        variable.id.range[1] < value.range[1]
      ) {
        return true
      }
    }
  }
}

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      description: 'enforce valid `v-slot` directives',
      category: undefined, // essential
      // TODO Change with major version.
      // category: 'essential',
      url: 'https://eslint.vuejs.org/rules/valid-v-slot.html'
    },
    fixable: null,
    schema: [],
    messages: {
      ownerMustBeCustomElement: "'v-slot' directive must be owned by a custom element, but '{{name}}' is not.",
      namedSlotMustBeOnTemplate: "Named slots must use '<template>' on a custom element.",
      defaultSlotMustBeOnTemplate: "Default slot must use '<template>' on a custom element when there are other named slots.",
      disallowDuplicateSlotsOnElement: "An element cannot have multiple 'v-slot' directives.",
      disallowDuplicateSlotsOnChildren: "An element cannot have multiple '<template>' elements which are distributed to the same slot.",
      disallowArgumentUseSlotParams: "Dynamic argument of 'v-slot' directive cannot use that slot parameter.",
      disallowAnyModifier: "'v-slot' directive doesn't support any modifier.",
      requireAttributeValue: "'v-slot' directive on a custom element requires that attribute value."
    }
  },

  create (context) {
    const sourceCode = context.getSourceCode()

    return utils.defineTemplateBodyVisitor(context, {
      "VAttribute[directive=true][key.name.name='slot']" (node) {
        const isDefaultSlot = node.key.argument == null || node.key.argument.name === 'default'
        const element = node.parent.parent
        const parentElement = element.parent
        const ownerElement = element.name === 'template' ? parentElement : element
        const vSlotsOnElement = getSlotDirectivesOnElement(element)
        const vSlotGroupsOnChildren = getSlotDirectivesOnChildren(ownerElement)

        // Verify location.
        if (!utils.isCustomComponent(ownerElement)) {
          context.report({
            node,
            messageId: 'ownerMustBeCustomElement',
            data: { name: ownerElement.rawName }
          })
        }
        if (!isDefaultSlot && element.name !== 'template') {
          context.report({
            node,
            messageId: 'namedSlotMustBeOnTemplate'
          })
        }
        if (ownerElement === element && vSlotGroupsOnChildren.length >= 1) {
          context.report({
            node,
            messageId: 'defaultSlotMustBeOnTemplate'
          })
        }

        // Verify duplication.
        if (vSlotsOnElement.length >= 2 && vSlotsOnElement[0] !== node) {
          // E.g., <my-component #one #two>
          context.report({
            node,
            messageId: 'disallowDuplicateSlotsOnElement'
          })
        }
        if (ownerElement === parentElement) {
          const vSlotGroupsOfSameSlot = filterSameSlot(vSlotGroupsOnChildren, node, sourceCode)
          const vFor = utils.getDirective(element, 'for')
          if (
            vSlotGroupsOfSameSlot.length >= 2 &&
            !vSlotGroupsOfSameSlot[0].includes(node)
          ) {
            // E.g., <template #one></template>
            //       <template #one></template>
            context.report({
              node,
              messageId: 'disallowDuplicateSlotsOnChildren'
            })
          }
          if (vFor && !isUsingIterationVar(node.key.argument, element)) {
            // E.g., <template v-for="x of xs" #one></template>
            context.report({
              node,
              messageId: 'disallowDuplicateSlotsOnChildren'
            })
          }
        }

        // Verify argument.
        if (isUsingScopeVar(node)) {
          context.report({
            node,
            messageId: 'disallowArgumentUseSlotParams'
          })
        }

        // Verify modifiers.
        if (node.key.modifiers.length >= 1) {
          context.report({
            node,
            messageId: 'disallowAnyModifier'
          })
        }

        // Verify value.
        if (ownerElement === element && isDefaultSlot && !utils.hasAttributeValue(node)) {
          context.report({
            node,
            messageId: 'requireAttributeValue'
          })
        }
      }
    })
  }
}
