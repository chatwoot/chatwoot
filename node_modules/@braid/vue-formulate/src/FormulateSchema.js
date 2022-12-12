import { cyrb43, has } from './libs/utils'

/**
 * Given an object and an index, complete an object for schema-generation.
 * @param {object} item
 * @param {int} index
 */
export function leaf (item, index = 0, rootListeners = {}) {
  if (item && typeof item === 'object' && !Array.isArray(item)) {
    let { children = null, component = 'FormulateInput', depth = 1, key = null, ...attrs } = item
    // these next two lines are required since `class` is a keyword and should
    // not be used in rest/spread operators.
    const cls = attrs.class || {}
    delete attrs.class
    // Event bindings
    const on = {}

    // Extract events from this instance
    const events = Object.keys(attrs)
      .reduce((events, key) => /^@/.test(key) ? Object.assign(events, { [key.substr(1)]: attrs[key] }) : events, {})

    // delete all events from the item
    Object.keys(events).forEach(event => {
      delete attrs[`@${event}`]
      on[event] = createListener(event, events[event], rootListeners)
    })

    const type = component === 'FormulateInput' ? (attrs.type || 'text') : component
    const name = attrs.name || type || 'el'
    if (!key) {
      // We need to generate a unique key if at all possible
      if (attrs.id) {
        // We've been given an id, so we should use it.
        key = attrs.id
      } else if (component !== 'FormulateInput' && typeof children === 'string') {
        // This is a simple text node container.
        key = `${type}-${cyrb43(children)}`
      } else {
        // This is a wrapper element
        key = `${type}-${name}-${depth}${attrs.name ? '' : '-' + index}`
      }
    }
    const els = Array.isArray(children)
      ? children.map(child => Object.assign(child, { depth: depth + 1 }))
      : children
    return Object.assign({ key, depth, attrs, component, class: cls, on }, els ? { children: els } : {})
  }
  return null
}

/**
 * Recursive function to create vNodes from a schema.
 * @param {Functon} h createElement
 * @param {Array|string} schema
 */
function tree (h, schema, rootListeners) {
  if (Array.isArray(schema)) {
    return schema.map((el, index) => {
      const item = leaf(el, index, rootListeners)
      return h(
        item.component,
        { attrs: item.attrs, class: item.class, key: item.key, on: item.on },
        item.children ? tree(h, item.children, rootListeners) : null
      )
    })
  }
  return schema
}

/**
 * Given an event name and handler, return a handler function that re-emits.
 *
 * @param {string} event
 * @param {string|boolean|function} handler
 */
function createListener (eventName, handler, rootListeners) {
  return function (...args) {
    // For event leafs like { '@blur': function () { ..do things... } }
    if (typeof handler === 'function') {
      return handler.call(this, ...args)
    }
    // For event leafs like { '@blur': 'nameBlur' }
    if (typeof handler === 'string' && has(rootListeners, handler)) {
      return rootListeners[handler].call(this, ...args)
    }
    // For event leafs like { '@blur': true }
    if (has(rootListeners, eventName)) {
      return rootListeners[eventName].call(this, ...args)
    }
  }
}

export default {
  functional: true,
  render: (h, { props, listeners }) => tree(h, props.schema, listeners)
}
