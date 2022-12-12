<template>
  <form
    :class="classes.form"
    v-bind="attributes"
    @submit.prevent="formSubmitted"
  >
    <FormulateSchema
      v-if="schema"
      :schema="schema"
      v-on="schemaListeners"
    />
    <FormulateErrors
      v-if="!hasFormErrorObservers"
      :context="formContext"
    />
    <slot v-bind="formContext" />
  </form>
</template>

<script>
import { arrayify, has, camel, extractAttributes, isEmpty } from './libs/utils'
import { classProps } from './libs/classes'
import useRegistry, { useRegistryComputed, useRegistryMethods, useRegistryProviders, useRegistryWatchers } from './libs/registry'
import FormSubmission from './FormSubmission'

export default {
  name: 'FormulateForm',
  inheritAttrs: false,
  provide () {
    return {
      ...useRegistryProviders(this, ['getGroupValues']),
      observeContext: this.addContextObserver,
      removeContextObserver: this.removeContextObserver
    }
  },
  model: {
    prop: 'formulateValue',
    event: 'input'
  },
  props: {
    name: {
      type: [String, Boolean],
      default: false
    },
    formulateValue: {
      type: Object,
      default: () => ({})
    },
    values: {
      type: [Object, Boolean],
      default: false
    },
    errors: {
      type: [Object, Boolean],
      default: false
    },
    formErrors: {
      type: Array,
      default: () => ([])
    },
    schema: {
      type: [Array, Boolean],
      default: false
    },
    keepModelData: {
      type: [Boolean, String],
      default: false
    },
    invalidMessage: {
      type: [Boolean, Function, String],
      default: false
    },
    debounce: {
      type: [Boolean, Number],
      default: false
    }
  },
  data () {
    return {
      ...useRegistry(this),
      formShouldShowErrors: false,
      contextObservers: [],
      namedErrors: [],
      namedFieldErrors: {},
      isLoading: false,
      hasFailedSubmit: false
    }
  },
  computed: {
    ...useRegistryComputed(),
    schemaListeners () {
      const { submit, ...listeners } = this.$listeners
      return listeners
    },
    pseudoProps () {
      return extractAttributes(this.$attrs, classProps.filter(p => /^form/.test(p)))
    },
    attributes () {
      const attrs = Object.keys(this.$attrs)
        .filter(attr => !has(this.pseudoProps, camel(attr)))
        .reduce((fields, field) => ({ ...fields, [field]: this.$attrs[field] }), {}) // Create an object of attributes to re-bind
      if (typeof this.name === 'string') {
        Object.assign(attrs, { name: this.name })
      }
      return attrs
    },
    hasErrors () {
      return Object.values(this.registry.errors).some(hasErrors => hasErrors)
    },
    isValid () {
      return !this.hasErrors
    },
    formContext () {
      return {
        errors: this.mergedFormErrors,
        pseudoProps: this.pseudoProps,
        hasErrors: this.hasErrors,
        value: this.proxy,
        hasValue: !isEmpty(this.proxy), // These have to be explicit for really silly nextTick reasons
        isValid: this.isValid,
        isLoading: this.isLoading,
        classes: this.classes
      }
    },
    classes () {
      return this.$formulate.classes({
        ...this.$props,
        ...this.pseudoProps,
        value: this.proxy,
        errors: this.mergedFormErrors,
        hasErrors: this.hasErrors,
        hasValue: !isEmpty(this.proxy),
        isValid: this.isValid,
        isLoading: this.isLoading,
        type: 'form',
        classification: 'form',
        attrs: this.$attrs
      })
    },
    invalidErrors () {
      if (this.hasFailedSubmit && this.hasErrors) {
        switch (typeof this.invalidMessage) {
          case 'string':
            return [this.invalidMessage]
          case 'object':
            return Array.isArray(this.invalidMessage) ? this.invalidMessage : []
          case 'function':
            const ret = this.invalidMessage(this.failingFields)
            return Array.isArray(ret) ? ret : [ret]
        }
      }
      return []
    },
    mergedFormErrors () {
      return this.formErrors.concat(this.namedErrors).concat(this.invalidErrors)
    },
    mergedFieldErrors () {
      const errors = {}
      if (this.errors) {
        for (const fieldName in this.errors) {
          errors[fieldName] = arrayify(this.errors[fieldName])
        }
      }
      for (const fieldName in this.namedFieldErrors) {
        errors[fieldName] = arrayify(this.namedFieldErrors[fieldName])
      }
      return errors
    },
    hasFormErrorObservers () {
      return !!this.errorObservers.filter(o => o.type === 'form').length
    },
    failingFields () {
      return Object.keys(this.registry.errors)
        .reduce((fields, field) => ({
          ...fields,
          ...(this.registry.errors[field] ? { [field]: this.registry.get(field) } : {})
        }), {})
    }
  },
  watch: {
    ...useRegistryWatchers(),
    formulateValue: {
      handler (values) {
        if (this.isVmodeled &&
          values &&
          typeof values === 'object'
        ) {
          this.setValues(values)
        }
      },
      deep: true
    },
    mergedFormErrors (errors) {
      this.errorObservers
        .filter(o => o.type === 'form')
        .forEach(o => o.callback(errors))
    }
  },
  created () {
    this.$formulate.register(this)
    this.applyInitialValues()
    this.$emit('created', this)
  },
  destroyed () {
    this.$formulate.deregister(this)
  },
  methods: {
    ...useRegistryMethods(),
    applyErrors ({ formErrors, inputErrors }) {
      // given an object of errors, apply them to this form
      this.namedErrors = formErrors
      this.namedFieldErrors = inputErrors
    },
    addContextObserver (callback) {
      if (!this.contextObservers.find(observer => observer === callback)) {
        this.contextObservers.push(callback)
        callback(this.formContext)
      }
    },
    removeContextObserver (callback) {
      this.contextObservers.filter(observer => observer !== callback)
    },
    registerErrorComponent (component) {
      if (!this.errorComponents.includes(component)) {
        this.errorComponents.push(component)
      }
    },
    formSubmitted () {
      if (this.isLoading) {
        return undefined
      }
      this.isLoading = true

      // perform validation here
      this.showErrors()
      const submission = new FormSubmission(this)

      // Wait for the submission handler
      const submitRawHandler = this.$listeners['submit-raw'] || this.$listeners.submitRaw
      const rawHandlerReturn = typeof submitRawHandler === 'function'
        ? submitRawHandler(submission)
        : Promise.resolve(submission)
      const willResolveRaw = rawHandlerReturn instanceof Promise
        ? rawHandlerReturn
        : Promise.resolve(rawHandlerReturn)
      return willResolveRaw
        .then(res => {
          const sub = (res instanceof FormSubmission ? res : submission)
          return sub.hasValidationErrors().then(hasErrors => [sub, hasErrors])
        })
        .then(([sub, hasErrors]) => {
          if (!hasErrors && typeof this.$listeners.submit === 'function') {
            return sub.values()
              .then(values => {
                // If the listener returns a promise, we want to wait for that
                // that promise to resolve, but when we do resolve, we only
                // want to resolve the submission values
                this.hasFailedSubmit = false
                const handlerReturn = this.$listeners.submit(values)
                return (handlerReturn instanceof Promise ? handlerReturn : Promise.resolve())
                  .then(() => values)
              })
          }
          return this.onFailedValidation()
        })
        .finally(() => {
          this.isLoading = false
        })
    },
    onFailedValidation () {
      this.hasFailedSubmit = true
      this.$emit('failed-validation', { ...this.failingFields })
      return this.$formulate.failedValidation(this)
    }
  }
}
</script>
