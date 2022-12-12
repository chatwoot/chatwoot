export default {
  inheritAttrs: false,
  functional: true,
  render (h, { props, data, parent, children }) {
    var p = parent
    var { name, forceWrap, context, ...mergeWithContext } = props

    // Look up the ancestor tree for the first FormulateInput
    while (p && p.$options.name !== 'FormulateInput') {
      p = p.$parent
    }

    // if we never found the proper parent, just end it.
    if (!p) {
      return null
    }

    // If we found a formulate input, check for a matching scoped slot
    if (p.$scopedSlots && p.$scopedSlots[props.name]) {
      return p.$scopedSlots[props.name]({ ...context, ...mergeWithContext })
    }

    // If we found no scoped slot, take the children and render those inside a wrapper if there are multiple
    if (Array.isArray(children) && (children.length > 1 || (forceWrap && children.length > 0))) {
      const { name, context, ...attrs } = data.attrs
      return h('div', { ...data, ...{ attrs } }, children)

    // If there is only one child, render it alone
    } else if (Array.isArray(children) && children.length === 1) {
      return children[0]
    }

    // If there are no children, render nothing
    return null
  }
}
