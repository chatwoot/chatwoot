import { arrayify, cap } from './utils'

/**
 * A list of available class keys in core. These can be added to by extending
 * the `classKeys` global option when registering formulate.
 */
export const classKeys = [
  // Globals
  'outer',
  'wrapper',
  'label',
  'element',
  'input',
  'help',
  'errors',
  'error',
  // Box
  'decorator',
  // Slider
  'rangeValue',
  // File
  'uploadArea',
  'uploadAreaMask',
  'files',
  'file',
  'fileName',
  'fileAdd',
  'fileAddInput',
  'fileRemove',
  'fileProgress',
  'fileUploadError',
  'fileImagePreview',
  'fileImagePreviewImage',
  'fileProgressInner',
  // Groups
  'grouping',
  'groupRepeatable',
  'groupRepeatableRemove',
  'groupAddMore',
  // Forms
  'form',
  'formErrors',
  'formError'
]

/**
 * State keys by default
 */
export const states = {
  hasErrors: c => c.hasErrors,
  hasValue: c => c.hasValue,
  isValid: c => c.isValid
}

/**
 * This function is responsible for providing VueFormulate’s default classes.
 * This function is called with the specific classKey ('wrapper' for example)
 * that it needs to generate classes for, and the context object. It always
 * returns an array.
 *
 * @param {string} classKey
 * @param {Object} context
 */
const classGenerator = (classKey, context) => {
  // camelCase to dash-case
  const key = classKey.replace(/[A-Z]/g, c => '-' + c.toLowerCase())
  const prefix = ['form', 'file'].includes(key.substr(0, 4)) ? '' : '-input'
  const element = ['decorator', 'range-value'].includes(key) ? '-element' : ''
  const base = `formulate${prefix}${element}${key !== 'outer' ? `-${key}` : ''}`
  return key === 'input' ? [] : [base].concat(classModifiers(base, classKey, context))
}

/**
 * Given a class key and a modifier, produce any additional classes.
 * @param {string} classKey
 * @param {Object} context
 */
const classModifiers = (base, classKey, context) => {
  const modifiers = []
  switch (classKey) {
    case 'label':
      modifiers.push(`${base}--${context.labelPosition}`)
      break
    case 'element':
      const type = context.classification === 'group' ? 'group' : context.type
      modifiers.push(`${base}--${type}`)
      // @todo DEPRECATED! This should be removed in a future version:
      if (type === 'group') {
        modifiers.push('formulate-input-group')
      }
      break
    case 'help':
      modifiers.push(`${base}--${context.helpPosition}`)
      break
    case 'form':
      if (context.name) {
        modifiers.push(`${base}--${context.name}`)
      }
  }
  return modifiers
}

/**
 * Generate a list of all the class props to accept.
 */
export const classProps = (() => {
  const stateKeys = [''].concat(Object.keys(states).map(s => cap(s)))
  // This reducer produces a key for every element key + state key variation
  return classKeys.reduce((props, classKey) => {
    return props.concat(stateKeys.reduce((keys, stateKey) => {
      keys.push(`${classKey}${stateKey}Class`)
      return keys
    }, []))
  }, [])
})()

/**
 * Given a string or array of classes and a modifier (function, string etc) apply
 * the modifications.
 *
 * @param {mixed} baseClass The initial class for a given key
 * @param {mixed} modifier A function, string, array etc that can be a class prop.
 * @param {Object} context The class context
 */
export function applyClasses (baseClass, modifier, context) {
  switch (typeof modifier) {
    case 'string':
      return modifier
    case 'function':
      return modifier(context, arrayify(baseClass))
    case 'object':
      if (Array.isArray(modifier)) {
        return arrayify(baseClass).concat(modifier)
      }
    /** allow fallthrough if object that isn’t an array */
    default:
      return baseClass
  }
}

/**
 * Given element class key
 * @param {string} elementKey the element class key we're generating for
 * @param {mixed} baseClass The initial classes for this key
 * @param {object} global Class definitions globally registered with options.classes
 * @param {Object} context Class context for this particular field, props included.
 */
export function applyStates (elementKey, baseClass, globals, context) {
  return Object.keys(states).reduce((classes, stateKey) => {
    // Step 1. Call the state function to determine if it has this state
    if (states[stateKey](context)) {
      const key = `${elementKey}${cap(stateKey)}`
      const propKey = `${key}Class`
      // Step 2. Apply any global state class keys
      if (globals[key]) {
        const modifier = (typeof globals[key] === 'string') ? arrayify(globals[key]) : globals[key]
        classes = applyClasses(classes, modifier, context)
      }
      // Step 3. Apply any prop state class keys
      if (context[propKey]) {
        const modifier = (typeof context[propKey] === 'string') ? arrayify(context[propKey]) : context[`${key}Class`]
        classes = applyClasses(classes, modifier, context)
      }
    }
    return classes
  }, baseClass)
}

/**
 * Function that produces all available classes.
 * @param {Object} context
 */
export default function (context) {
  return classKeys.reduce((classes, classKey) => Object.assign(classes, {
    [classKey]: classGenerator(classKey, context)
  }), {})
}
