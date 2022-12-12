<template>
  <div
    :class="context.classes.outer"
    :data-classification="classification"
    :data-has-errors="hasErrors"
    :data-is-showing-errors="hasVisibleErrors"
    :data-has-value="hasValue"
    :data-type="type"
  >
    <div :class="context.classes.wrapper">
      <slot
        v-if="context.labelPosition === 'before'"
        name="label"
        v-bind="context"
      >
        <component
          :is="context.slotComponents.label"
          v-if="context.hasLabel"
          v-bind="context.slotProps.label"
          :context="context"
        />
      </slot>
      <slot
        v-if="context.helpPosition === 'before'"
        name="help"
        v-bind="context"
      >
        <component
          :is="context.slotComponents.help"
          v-if="context.help"
          v-bind="context.slotProps.help"
          :context="context"
        />
      </slot>
      <slot
        name="element"
        v-bind="context"
      >
        <component
          :is="context.component"
          :context="context"
          v-bind="context.slotProps.component"
          v-on="listeners"
        >
          <slot v-bind="context" />
        </component>
      </slot>
      <slot
        v-if="context.labelPosition === 'after'"
        name="label"
        v-bind="context"
      >
        <component
          :is="context.slotComponents.label"
          v-if="context.hasLabel"
          :context="context"
          v-bind="context.slotProps.label"
        />
      </slot>
    </div>
    <slot
      v-if="context.helpPosition === 'after'"
      name="help"
      v-bind="context"
    >
      <component
        :is="context.slotComponents.help"
        v-if="context.help"
        :context="context"
        v-bind="context.slotProps.help"
      />
    </slot>
    <slot
      name="errors"
      v-bind="context"
    >
      <component
        :is="context.slotComponents.errors"
        v-if="!context.disableErrors"
        :type="context.slotComponents.errors === 'FormulateErrors' ? 'input' : false"
        :context="context"
        v-bind="context.slotProps.errors"
      />
    </slot>
  </div>
</template>

<script>
import context from './libs/context'
import { equals, parseRules, camel, has, arrayify, groupBails, isEmpty, createDebouncer } from './libs/utils'

export default {
  name: 'FormulateInput',
  inheritAttrs: false,
  provide () {
    return {
      // Allows sub-components of this input to register arbitrary rules.
      formulateRegisterRule: this.registerRule,
      formulateRemoveRule: this.removeRule
    }
  },
  inject: {
    formulateSetter: { default: undefined },
    formulateFieldValidation: { default: () => () => ({}) },
    formulateRegister: { default: undefined },
    formulateDeregister: { default: undefined },
    getFormValues: { default: () => () => ({}) },
    getGroupValues: { default: undefined },
    validateDependents: { default: () => () => {} },
    observeErrors: { default: undefined },
    removeErrorObserver: { default: undefined },
    isSubField: { default: () => () => false }
  },
  model: {
    prop: 'formulateValue',
    event: 'input'
  },
  props: {
    type: {
      type: String,
      default: 'text'
    },
    name: {
      type: [String, Boolean],
      default: true
    },
    /* eslint-disable */
    formulateValue: {
      default: ''
    },
    value: {
      default: false
    },
    /* eslint-enable */
    options: {
      type: [Object, Array, Boolean],
      default: false
    },
    optionGroups: {
      type: [Object, Boolean],
      default: false
    },
    id: {
      type: [String, Boolean, Number],
      default: false
    },
    label: {
      type: [String, Boolean],
      default: false
    },
    labelPosition: {
      type: [String, Boolean],
      default: false
    },
    limit: {
      type: [String, Number],
      default: Infinity,
      validator: value => Infinity || parseInt(value, 10) == value // eslint-disable-line eqeqeq
    },
    minimum: {
      type: [String, Number],
      default: 0,
      validator: value => parseInt(value, 10) == value // eslint-disable-line eqeqeq
    },
    help: {
      type: [String, Boolean],
      default: false
    },
    helpPosition: {
      type: [String, Boolean],
      default: false
    },
    isGrouped: {
      type: Boolean,
      default: false
    },
    errors: {
      type: [String, Array, Boolean],
      default: false
    },
    removePosition: {
      type: [String, Boolean],
      default: false
    },
    repeatable: {
      type: Boolean,
      default: false
    },
    validation: {
      type: [String, Boolean, Array],
      default: false
    },
    validationName: {
      type: [String, Boolean],
      default: false
    },
    error: {
      type: [String, Boolean],
      default: false
    },
    errorBehavior: {
      type: String,
      default: 'blur',
      validator: function (value) {
        return ['blur', 'live', 'submit', 'value'].includes(value)
      }
    },
    showErrors: {
      type: Boolean,
      default: false
    },
    groupErrors: {
      type: Object,
      default: () => ({}),
      validator: (value) => {
        const isK = /^\d+\./
        return !Object.keys(value).some(k => !isK.test(k))
      }
    },
    imageBehavior: {
      type: String,
      default: 'preview'
    },
    uploadUrl: {
      type: [String, Boolean],
      default: false
    },
    uploader: {
      type: [Function, Object, Boolean],
      default: false
    },
    uploadBehavior: {
      type: String,
      default: 'live'
    },
    preventWindowDrops: {
      type: Boolean,
      default: true
    },
    showValue: {
      type: [String, Boolean],
      default: false
    },
    validationMessages: {
      type: Object,
      default: () => ({})
    },
    validationRules: {
      type: Object,
      default: () => ({})
    },
    checked: {
      type: [String, Boolean],
      default: false
    },
    disableErrors: {
      type: Boolean,
      default: false
    },
    addLabel: {
      type: [Boolean, String],
      default: true
    },
    removeLabel: {
      type: [Boolean, String],
      default: false
    },
    keepModelData: {
      type: [Boolean, String],
      default: 'inherit'
    },
    ignored: {
      type: [Boolean, String],
      default: false
    },
    debounce: {
      type: [Boolean, Number],
      default: false
    },
    preventDeregister: {
      type: Boolean,
      default: false
    }
  },
  data () {
    return {
      defaultId: this.$formulate.nextId(this),
      localAttributes: {},
      localErrors: [],
      localGroupErrors: {},
      proxy: this.getInitialValue(),
      behavioralErrorVisibility: (this.errorBehavior === 'live'),
      formShouldShowErrors: false,
      validationErrors: [],
      pendingValidation: Promise.resolve(),
      // These registries are used for injected messages registrants only (mostly internal).
      ruleRegistry: [],
      messageRegistry: {},
      touched: false,
      debounceDelay: this.debounce,
      dSet: createDebouncer(),
      mntd: false
    }
  },
  computed: {
    ...context,
    classification () {
      const classification = this.$formulate.classify(this.type)
      return (classification === 'box' && this.options) ? 'group' : classification
    },
    component () {
      return (this.classification === 'group') ? 'FormulateInputGroup' : this.$formulate.component(this.type)
    },
    parsedValidationRules () {
      const parsedValidationRules = {}
      Object.keys(this.validationRules).forEach(key => {
        parsedValidationRules[camel(key)] = this.validationRules[key]
      })
      return parsedValidationRules
    },
    parsedValidation () {
      return parseRules(this.validation, this.$formulate.rules(this.parsedValidationRules))
    },
    messages () {
      const messages = {}
      Object.keys(this.validationMessages).forEach((key) => {
        messages[camel(key)] = this.validationMessages[key]
      })
      Object.keys(this.messageRegistry).forEach((key) => {
        messages[camel(key)] = this.messageRegistry[key]
      })
      return messages
    }
  },
  watch: {
    '$attrs': {
      handler (value) {
        this.updateLocalAttributes(value)
      },
      deep: true
    },
    proxy: {
      handler: function (newValue, oldValue) {
        this.performValidation()
        if (!this.isVmodeled && !equals(newValue, oldValue, this.type === 'group')) {
          this.context.model = newValue
        }
        this.validateDependents(this)
        if (!this.touched && newValue) {
          this.touched = true
        }
      },
      deep: true
    },
    formulateValue: {
      handler: function (newValue, oldValue) {
        if (this.isVmodeled && !equals(newValue, oldValue, this.type === 'group')) {
          this.context.model = newValue
        }
      },
      deep: true
    },
    showValidationErrors: {
      handler (val) {
        this.$emit('error-visibility', val)
      },
      immediate: true
    },
    validation: {
      handler () {
        this.performValidation()
      },
      deep: true
    },
    touched (value) {
      if (this.errorBehavior === 'value' && value) {
        this.behavioralErrorVisibility = value
      }
    },
    debounce (value) {
      this.debounceDelay = value
    }
  },
  created () {
    this.applyInitialValue()
    if (this.formulateRegister && typeof this.formulateRegister === 'function') {
      this.formulateRegister(this.nameOrFallback, this)
    }
    this.applyDefaultValue()
    if (!this.disableErrors && typeof this.observeErrors === 'function') {
      this.observeErrors({ callback: this.setErrors, type: 'input', field: this.nameOrFallback })
      if (this.type === 'group') {
        this.observeErrors({ callback: this.setGroupErrors, type: 'group', field: this.nameOrFallback })
      }
    }
    this.updateLocalAttributes(this.$attrs)
    this.performValidation()
    if (this.hasValue) {
      this.touched = true
    }
  },
  mounted () {
    this.mntd = true
  },
  beforeDestroy () {
    if (!this.disableErrors && typeof this.removeErrorObserver === 'function') {
      this.removeErrorObserver(this.setErrors)
      if (this.type === 'group') {
        this.removeErrorObserver(this.setGroupErrors)
      }
    }
    if (typeof this.formulateDeregister === 'function' && !this.preventDeregister) {
      this.formulateDeregister(this.nameOrFallback)
    }
  },
  methods: {
    getInitialValue () {
      // Manually request classification, pre-computed props
      var classification = this.$formulate.classify(this.type)
      classification = (classification === 'box' && this.options) ? 'group' : classification
      if (classification === 'box' && this.checked) {
        return this.value || true
      } else if (has(this.$options.propsData, 'value') && classification !== 'box') {
        return this.value
      } else if (has(this.$options.propsData, 'formulateValue')) {
        return this.formulateValue
      } else if (classification === 'group') {
        // Set the value of an empty group
        return Object.defineProperty(this.type === 'group' ? [{}] : [], '__init', { value: true })
      }
      return ''
    },
    applyInitialValue () {
      // This should only be run immediately on created and ensures that the
      // proxy and the model are both the same before any additional registration.
      if (
        !equals(this.context.model, this.proxy) &&
        // we dont' want to set the model if we are a sub-box of a multi-box field
        (this.classification !== 'box' || has(this.$options.propsData, 'options'))
      ) {
        this.context.model = this.proxy
        this.$emit('input', this.proxy)
      }
    },
    applyDefaultValue () {
      // Some inputs have may have special logic determining what to do if they
      // are still strictly undefined after applyInitialValue and registration.
      if (
        this.type === 'select' &&
        !this.context.placeholder &&
        isEmpty(this.proxy) &&
        !this.isVmodeled &&
        this.value === false &&
        this.context.options.length
      ) {
        if (!has(this.$attrs, 'multiple')) {
          // In this condition we have a blank select input with no value, by
          // default HTML will select the first element, so we emulate that.
          // See https://github.com/wearebraid/vue-formulate/issues/165
          this.context.model = this.context.options[0].value
        } else {
          // In this condition we have a multi select input, which should use
          // an array as it's v-model base state.
          this.context.model = []
        }
      }
    },
    updateLocalAttributes (value) {
      if (!equals(value, this.localAttributes)) {
        this.localAttributes = value
      }
    },
    performValidation () {
      let rules = parseRules(this.validation, this.$formulate.rules(this.parsedValidationRules))
      // Add in ruleRegistry rules. These are added directly via injection from
      // children and not part of the standard validation rule set.
      rules = this.ruleRegistry.length ? this.ruleRegistry.concat(rules) : rules
      this.pendingValidation = this.runRules(rules)
        .then(messages => this.didValidate(messages))
      return this.pendingValidation
    },
    runRules (rules) {
      const run = ([rule, args, ruleName, modifier]) => {
        var res = rule({
          value: this.context.model,
          getFormValues: (...args) => this.getFormValues(this, ...args),
          getGroupValues: (...args) => this[`get${this.getGroupValues ? 'Group' : 'Form'}Values`](this, ...args),
          name: this.context.name
        }, ...args)
        res = (res instanceof Promise) ? res : Promise.resolve(res)
        return res.then(result => result ? false : this.getMessage(ruleName, args))
      }

      return new Promise(resolve => {
        // We break our rules into resolvable groups. These groups are
        // adjacent rules that can be resolved simultaneously. For example
        // consider: required|min:6,length here both rules resolve in parallel.
        // but ^required|min:6,length cannot be resolved in parallel because
        // the execution of the min rule requires passing resolution of the
        // required rule due to bailing. `resolveGroups` runs/resolves each of
        // these resolution groups, while `groupBails` is responsible for
        // producing them.
        const resolveGroups = (groups, allMessages = []) => {
          const ruleGroup = groups.shift()
          if (Array.isArray(ruleGroup) && ruleGroup.length) {
            Promise.all(ruleGroup.map(run))
              // Filter out any simple falsy values to prevent triggering errors
              .then(messages => messages.filter(m => !!m))
              .then(messages => {
                messages = Array.isArray(messages) ? messages : []
                // The rule passed or its a non-bailing group, and there are additional groups to check, continue
                if ((!messages.length || !ruleGroup.bail) && groups.length) {
                  return resolveGroups(groups, allMessages.concat(messages))
                }
                // Filter out any empty error messages, this is important for
                // the `optional` rule. It uses a hard-coded empty array [] as
                // the message to trigger bailing, but we obviously don’t want
                // this message to make it out of this resolver.
                return resolve(allMessages.concat(messages).filter(m => !isEmpty(m)))
              })
          } else {
            resolve([])
          }
        }
        // Produce our resolution groups, and then run them
        resolveGroups(groupBails(rules))
      })
    },
    didValidate (messages) {
      const validationChanged = !equals(messages, this.validationErrors)
      this.validationErrors = messages
      if (validationChanged) {
        const errorObject = this.getErrorObject()
        this.$emit('validation', errorObject)
        if (this.formulateFieldValidation && typeof this.formulateFieldValidation === 'function') {
          this.formulateFieldValidation(errorObject)
        }
      }
    },
    getMessage (ruleName, args) {
      return this.getMessageFunc(ruleName)({
        args,
        name: this.mergedValidationName,
        value: this.context.model,
        vm: this,
        formValues: this.getFormValues(this),
        getFormValues: (...args) => this.getFormValues(this, ...args),
        getGroupValues: (...args) => this[`get${this.getGroupValues ? 'Group' : 'Form'}Values`](this, ...args)
      })
    },
    getMessageFunc (ruleName) {
      ruleName = camel(ruleName)
      if (ruleName === 'optional') {
        // Optional rules need to trigger bailing by having a message, but pass
        // the simple double bang (!!) filer, any non-string value will have
        // this effect.
        return () => ([])
      }
      if (this.messages && typeof this.messages[ruleName] !== 'undefined') {
        switch (typeof this.messages[ruleName]) {
          case 'function':
            return this.messages[ruleName]
          case 'string':
          case 'boolean':
            return () => this.messages[ruleName]
        }
      }
      return (context) => this.$formulate.validationMessage(ruleName, context, this)
    },
    hasValidationErrors () {
      return new Promise(resolve => {
        this.$nextTick(() => {
          this.pendingValidation.then(() => resolve(!!this.validationErrors.length))
        })
      })
    },
    getValidationErrors () {
      return new Promise(resolve => {
        this.$nextTick(() => this.pendingValidation.then(() => resolve(this.getErrorObject())))
      })
    },
    getErrorObject () {
      return {
        name: this.context.nameOrFallback || this.context.name,
        errors: this.validationErrors.filter(s => typeof s === 'string'),
        hasErrors: !!this.validationErrors.length
      }
    },
    setErrors (errors) {
      this.localErrors = arrayify(errors)
    },
    setGroupErrors (groupErrors) {
      this.localGroupErrors = groupErrors
    },
    registerRule (rule, args, ruleName, message = null) {
      if (!this.ruleRegistry.some(r => r[2] === ruleName)) {
        // These are the raw rule format since they will be used directly.
        this.ruleRegistry.push([rule, args, ruleName])
        if (message !== null) {
          this.messageRegistry[ruleName] = message
        }
      }
    },
    removeRule (key) {
      const ruleIndex = this.ruleRegistry.findIndex(r => r[2] === key)
      if (ruleIndex >= 0) {
        this.ruleRegistry.splice(ruleIndex, 1)
        delete this.messageRegistry[key]
      }
    }
  }
}
</script>
