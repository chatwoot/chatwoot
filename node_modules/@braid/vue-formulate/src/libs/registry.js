import { equals, has, isEmpty, setId } from './utils'

/**
 * Component registry with inherent depth to handle complex nesting. This is
 * important for features such as grouped fields.
 */
class Registry {
  /**
   * Create a new registry of components.
   * @param {vm} ctx The host vm context of the registry.
   */
  constructor (ctx) {
    this.registry = new Map()
    this.errors = {}
    this.ctx = ctx
  }

  /**
   * Add an item to the registry.
   * @param {string|array} key
   * @param {vue} component
   */
  add (name, component) {
    this.registry.set(name, component)
    this.errors = { ...this.errors, [name]: component.getErrorObject().hasErrors }
    return this
  }

  /**
   * Remove an item from the registry.
   * @param {string} name
   */
  remove (name) {
    // Clean up dependent validations
    this.ctx.deps.delete(this.registry.get(name))
    this.ctx.deps.forEach(dependents => dependents.delete(name))

    // Determine if we're keep the model data or destroying it
    let keepData = this.ctx.keepModelData
    if (!keepData && this.registry.has(name) && this.registry.get(name).keepModelData !== 'inherit') {
      keepData = this.registry.get(name).keepModelData
    }
    if (this.ctx.preventCleanup) {
      keepData = true
    }

    this.registry.delete(name)
    const { [name]: trash, ...errorValues } = this.errors
    this.errors = errorValues

    // Clean up the model if we don't explicitly state otherwise
    if (!keepData) {
      const { [name]: value, ...newProxy } = this.ctx.proxy
      if (this.ctx.uuid) {
        // If the registry context has a uuid (row.__id) be sure to include it in
        // this input event so it can replace values in the proper row.
        setId(newProxy, this.ctx.uuid)
      }
      this.ctx.proxy = newProxy
      this.ctx.$emit('input', this.ctx.proxy)
    }
    return this
  }

  /**
   * Check if the registry has the given key.
   * @param {string|array} key
   */
  has (key) {
    return this.registry.has(key)
  }

  /**
   * Get a particular registry value.
   * @param {string} key
   */
  get (key) {
    return this.registry.get(key)
  }

  /**
   * Map over the registry (recursively).
   * @param {function} callback
   */
  map (callback) {
    const value = {}
    this.registry.forEach((component, field) => Object.assign(value, { [field]: callback(component, field) }))
    return value
  }

  /**
   * Return the keys of the registry.
   */
  keys () {
    return Array.from(this.registry.keys())
  }

  /**
   * Fully register a component.
   * @param {string} field name of the field.
   * @param {vm} component the actual component instance.
   */
  register (field, component) {
    if (has(component.$options.propsData, 'ignored')) {
      // Any presence of the `ignored` prop will ensure this input is skipped.
      return false
    }
    if (this.registry.has(field)) {
      // Here we check to see if the field we are about to register is going to
      // immediately be removed. That indicates this field is switching like in
      // a v-if:
      //
      // <FormulateInput name="foo" v-if="condition" />
      // <FormulateInput name="foo" v-else />
      //
      // Because created() fires _before_ destroyed() the new field would not
      // register because the old one would not have yet unregistered. By
      // checking if field we're trying to register is gone on the nextTick we
      // can assume it was supposed to register, and do so "again".
      this.ctx.$nextTick(() => !this.registry.has(field) ? this.register(field, component) : false)
      return false
    }
    this.add(field, component)
    const hasVModelValue = has(component.$options.propsData, 'formulateValue')
    const hasValue = has(component.$options.propsData, 'value')
    // This is not reactive
    const debounceDelay = this.ctx.debounce || this.ctx.debounceDelay || (this.ctx.context && this.ctx.context.debounceDelay)
    if (debounceDelay && !has(component.$options.propsData, 'debounce')) {
      component.debounceDelay = debounceDelay
    }
    if (
      !hasVModelValue &&
      this.ctx.hasInitialValue &&
      !isEmpty(this.ctx.initialValues[field])
    ) {
      // In the case that the form is carrying an initial value and the
      // element is not, set it directly.
      component.context.model = this.ctx.initialValues[field]
    } else if (
      (hasVModelValue || hasValue) &&
      !equals(component.proxy, this.ctx.initialValues[field], true)
    ) {
      // In this case, the field is v-modeled or has an initial value and the
      // registry has no value or a different value, so use the field value
      this.ctx.setFieldValue(field, component.proxy)
    }
    if (this.childrenShouldShowErrors) {
      component.formShouldShowErrors = true
    }
  }

  /**
   * Reduce the registry.
   * @param {function} callback
   */
  reduce (callback, accumulator) {
    this.registry.forEach((component, field) => {
      accumulator = callback(accumulator, component, field)
    })
    return accumulator
  }

  /**
   * Data props to expose.
   */
  dataProps () {
    return {
      proxy: {},
      registry: this,
      register: this.register.bind(this),
      deregister: field => this.remove(field),
      childrenShouldShowErrors: false,
      errorObservers: [],
      deps: new Map(),
      preventCleanup: false
    }
  }
}

/**
 * The context component.
 * @param {component} contextComponent
 */
export default function useRegistry (contextComponent) {
  const registry = new Registry(contextComponent)
  return registry.dataProps()
}

/**
 * Computed properties related to the registry.
 */
export function useRegistryComputed (options = {}) {
  return {
    hasInitialValue () {
      return (
        (this.formulateValue && typeof this.formulateValue === 'object') ||
        (this.values && typeof this.values === 'object') ||
        (this.isGrouping && typeof this.context.model[this.index] === 'object')
      )
    },
    isVmodeled () {
      return !!(this.$options.propsData.hasOwnProperty('formulateValue') &&
        this._events &&
        Array.isArray(this._events.input) &&
        this._events.input.length)
    },
    initialValues () {
      if (
        has(this.$options.propsData, 'formulateValue') &&
        typeof this.formulateValue === 'object'
      ) {
        // If there is a v-model on the form/group, use those values as first priority
        return { ...this.formulateValue } // @todo - use a deep clone to detach reference types?
      } else if (
        has(this.$options.propsData, 'values') &&
        typeof this.values === 'object'
      ) {
        // If there are values, use them as secondary priority
        return { ...this.values }
      } else if (
        this.isGrouping && typeof this.context.model[this.index] === 'object'
      ) {
        return this.context.model[this.index]
      }
      return {}
    },
    mergedGroupErrors () {
      const hasSubFields = /^([^.\d+].*?)\.(\d+\..+)$/
      return Object.keys(this.mergedFieldErrors)
        .filter(k => hasSubFields.test(k))
        .reduce((groupErrorsByRoot, k) => {
          let [, rootField, groupKey] = k.match(hasSubFields)
          if (!groupErrorsByRoot[rootField]) {
            groupErrorsByRoot[rootField] = {}
          }
          Object.assign(groupErrorsByRoot[rootField], { [groupKey]: this.mergedFieldErrors[k] })
          return groupErrorsByRoot
        }, {})
    }
  }
}

/**
 * Methods used in the registry.
 */
export function useRegistryMethods (without = []) {
  const methods = {
    applyInitialValues () {
      if (this.hasInitialValue) {
        this.proxy = { ...this.initialValues }
      }
    },
    setFieldValue (field, value) {
      if (value === undefined) {
        // undefined values should be removed from the form model
        const { [field]: value, ...proxy } = this.proxy
        this.proxy = proxy
      } else {
        Object.assign(this.proxy, { [field]: value })
      }
      this.$emit('input', { ...this.proxy })
    },
    valueDeps (callerCmp) {
      return Object.keys(this.proxy)
        .reduce((o, k) => Object.defineProperty(o, k, {
          enumerable: true,
          get: () => {
            const callee = this.registry.get(k)
            this.deps.set(callerCmp, this.deps.get(callerCmp) || new Set())
            if (callee) {
              this.deps.set(callee, this.deps.get(callee) || new Set())
              this.deps.get(callee).add(callerCmp.name)
            }
            this.deps.get(callerCmp).add(k)
            return this.proxy[k]
          }
        }), Object.create(null))
    },
    validateDeps (callerCmp) {
      if (this.deps.has(callerCmp)) {
        this.deps.get(callerCmp).forEach(field => this.registry.has(field) && this.registry.get(field).performValidation())
      }
    },
    hasValidationErrors () {
      return Promise.all(this.registry.reduce((resolvers, cmp, name) => {
        resolvers.push(cmp.performValidation() && cmp.getValidationErrors())
        return resolvers
      }, [])).then(errorObjects => errorObjects.some(item => item.hasErrors))
    },
    showErrors () {
      this.childrenShouldShowErrors = true
      this.registry.map(input => {
        input.formShouldShowErrors = true
      })
    },
    hideErrors () {
      this.childrenShouldShowErrors = false
      this.registry.map(input => {
        input.formShouldShowErrors = false
        input.behavioralErrorVisibility = false
      })
    },
    setValues (values) {
      // Collect all keys, existing and incoming
      const keys = Array.from(new Set(Object.keys(values || {}).concat(Object.keys(this.proxy))))
      keys.forEach(field => {
        const input = this.registry.has(field) && this.registry.get(field)
        let value = values ? values[field] : undefined
        if (input && !equals(input.proxy, value, true)) {
          input.context.model = value
        }
        if (!equals(value, this.proxy[field], true)) {
          this.setFieldValue(field, value)
        }
      })
    },
    updateValidation (errorObject) {
      if (has(this.registry.errors, errorObject.name)) {
        this.registry.errors[errorObject.name] = errorObject.hasErrors
      }
      this.$emit('validation', errorObject)
    },
    addErrorObserver (observer) {
      if (!this.errorObservers.find(obs => observer.callback === obs.callback)) {
        this.errorObservers.push(observer)
        if (observer.type === 'form') {
          observer.callback(this.mergedFormErrors)
        } else if (observer.type === 'group' && has(this.mergedGroupErrors, observer.field)) {
          observer.callback(this.mergedGroupErrors[observer.field])
        } else if (has(this.mergedFieldErrors, observer.field)) {
          observer.callback(this.mergedFieldErrors[observer.field])
        }
      }
    },
    removeErrorObserver (observer) {
      this.errorObservers = this.errorObservers.filter(obs => obs.callback !== observer)
    }
  }
  return Object.keys(methods).reduce((withMethods, key) => {
    return without.includes(key) ? withMethods : { ...withMethods, [key]: methods[key] }
  }, {})
}

/**
 * Unified registry watchers.
 */
export function useRegistryWatchers () {
  return {
    mergedFieldErrors: {
      handler (errors) {
        this.errorObservers
          .filter(o => o.type === 'input')
          .forEach(o => o.callback(errors[o.field] || []))
      },
      immediate: true
    },
    mergedGroupErrors: {
      handler (errors) {
        this.errorObservers
          .filter(o => o.type === 'group')
          .forEach(o => o.callback(errors[o.field] || {}))
      },
      immediate: true
    }
  }
}

/**
 * Providers related to the registry.
 */
export function useRegistryProviders (ctx, without = []) {
  const providers = {
    formulateSetter: ctx.setFieldValue,
    formulateRegister: ctx.register,
    formulateDeregister: ctx.deregister,
    formulateFieldValidation: ctx.updateValidation,
    // Provided on forms only to let getFormValues to fall back to form
    getFormValues: ctx.valueDeps,
    // Provided on groups only to expose group-level items
    getGroupValues: ctx.valueDeps,
    validateDependents: ctx.validateDeps,
    observeErrors: ctx.addErrorObserver,
    removeErrorObserver: ctx.removeErrorObserver
  }
  const p = Object.keys(providers)
    .filter(provider => !without.includes(provider))
    .reduce((useProviders, provider) => Object.assign(useProviders, { [provider]: providers[provider] }), {})
  return p
}
