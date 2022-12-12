/**
 * @fileoverview enforce usage of `exact` modifier on `v-on`.
 * @author Armano
 */
'use strict'

// ------------------------------------------------------------------------------
// Requirements
// ------------------------------------------------------------------------------

const utils = require('../utils')

const SYSTEM_MODIFIERS = new Set(['ctrl', 'shift', 'alt', 'meta'])
const GLOBAL_MODIFIERS = new Set(['stop', 'prevent', 'capture', 'self', 'once', 'passive', 'native'])

// ------------------------------------------------------------------------------
// Helpers
// ------------------------------------------------------------------------------

/**
 * Finds and returns all keys for event directives
 *
 * @param {array} attributes Element attributes
 * @param {SourceCode} sourceCode The source code object.
 * @returns {array[object]} [{ name, node, modifiers }]
 */
function getEventDirectives (attributes, sourceCode) {
  return attributes
    .filter(attribute =>
      attribute.directive &&
      attribute.key.name.name === 'on'
    )
    .map(attribute => ({
      name: attribute.key.argument ? sourceCode.getText(attribute.key.argument) : '',
      node: attribute.key,
      modifiers: attribute.key.modifiers.map(modifier => modifier.name)
    }))
}

/**
 * Checks whether given modifier is key modifier
 *
 * @param {string} modifier
 * @returns {boolean}
 */
function isKeyModifier (modifier) {
  return !GLOBAL_MODIFIERS.has(modifier) && !SYSTEM_MODIFIERS.has(modifier)
}

/**
 * Checks whether given modifier is system one
 *
 * @param {string} modifier
 * @returns {boolean}
 */
function isSystemModifier (modifier) {
  return SYSTEM_MODIFIERS.has(modifier)
}

/**
 * Checks whether given any of provided modifiers
 * has system modifier
 *
 * @param {array} modifiers
 * @returns {boolean}
 */
function hasSystemModifier (modifiers) {
  return modifiers.some(isSystemModifier)
}

/**
 * Groups all events in object,
 * with keys represinting each event name
 *
 * @param {array} events
 * @returns {object} { click: [], keypress: [] }
 */
function groupEvents (events) {
  return events.reduce((acc, event) => {
    if (acc[event.name]) {
      acc[event.name].push(event)
    } else {
      acc[event.name] = [event]
    }

    return acc
  }, {})
}

/**
 * Creates alphabetically sorted string with system modifiers
 *
 * @param {array[string]} modifiers
 * @returns {string} e.g. "alt,ctrl,del,shift"
 */
function getSystemModifiersString (modifiers) {
  return modifiers.filter(isSystemModifier).sort().join(',')
}

/**
 * Creates alphabetically sorted string with key modifiers
 *
 * @param {array[string]} modifiers
 * @returns {string} e.g. "enter,tab"
 */
function getKeyModifiersString (modifiers) {
  return modifiers.filter(isKeyModifier).sort().join(',')
}

/**
 * Compares two events based on their modifiers
 * to detect possible event leakeage
 *
 * @param {object} baseEvent
 * @param {object} event
 * @returns {boolean}
 */
function hasConflictedModifiers (baseEvent, event) {
  if (
    event.node === baseEvent.node ||
    event.modifiers.includes('exact')
  ) return false

  const eventKeyModifiers = getKeyModifiersString(event.modifiers)
  const baseEventKeyModifiers = getKeyModifiersString(baseEvent.modifiers)

  if (
    eventKeyModifiers && baseEventKeyModifiers &&
    eventKeyModifiers !== baseEventKeyModifiers
  ) return false

  const eventSystemModifiers = getSystemModifiersString(event.modifiers)
  const baseEventSystemModifiers = getSystemModifiersString(baseEvent.modifiers)

  return (
    baseEvent.modifiers.length >= 1 &&
    baseEventSystemModifiers !== eventSystemModifiers &&
    baseEventSystemModifiers.indexOf(eventSystemModifiers) > -1
  )
}

/**
 * Searches for events that might conflict with each other
 *
 * @param {array} events
 * @returns {array} conflicted events, without duplicates
 */
function findConflictedEvents (events) {
  return events.reduce((acc, event) => {
    return [
      ...acc,
      ...events
        .filter(evt => !acc.find(e => evt === e)) // No duplicates
        .filter(hasConflictedModifiers.bind(null, event))
    ]
  }, [])
}

// ------------------------------------------------------------------------------
// Rule details
// ------------------------------------------------------------------------------

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description: 'enforce usage of `exact` modifier on `v-on`',
      category: 'essential',
      url: 'https://eslint.vuejs.org/rules/use-v-on-exact.html'
    },
    fixable: null,
    schema: []
  },

  /**
   * Creates AST event handlers for use-v-on-exact.
   *
   * @param {RuleContext} context - The rule context.
   * @returns {Object} AST event handlers.
   */
  create (context) {
    const sourceCode = context.getSourceCode()

    return utils.defineTemplateBodyVisitor(context, {
      VStartTag (node) {
        if (node.attributes.length === 0) return

        const isCustomComponent = utils.isCustomComponent(node.parent)
        let events = getEventDirectives(node.attributes, sourceCode)

        if (isCustomComponent) {
          // For components consider only events with `native` modifier
          events = events.filter(event => event.modifiers.includes('native'))
        }

        const grouppedEvents = groupEvents(events)

        Object.keys(grouppedEvents).forEach(eventName => {
          const eventsInGroup = grouppedEvents[eventName]
          const hasEventWithKeyModifier = eventsInGroup.some(event =>
            hasSystemModifier(event.modifiers)
          )

          if (!hasEventWithKeyModifier) return

          const conflictedEvents = findConflictedEvents(eventsInGroup)

          conflictedEvents.forEach(e => {
            context.report({
              node: e.node,
              loc: e.node.loc,
              message: "Consider to use '.exact' modifier."
            })
          })
        })
      }
    })
  }
}
