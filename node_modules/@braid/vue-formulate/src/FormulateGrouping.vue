<template>
  <FormulateSlot
    name="grouping"
    :class="context.classes.grouping"
    :context="context"
    :force-wrap="context.repeatable"
  >
    <FormulateRepeatableProvider
      v-for="(item, index) in items"
      :key="item.__id"
      :index="index"
      :context="context"
      :uuid="item.__id"
      :errors="groupErrors[index]"
      @remove="removeItem"
      @input="(values) => setItem(index, values)"
    >
      <slot />
    </FormulateRepeatableProvider>
  </FormulateSlot>
</template>

<script>
import { setId, has, equals } from './libs/utils'

export default {
  name: 'FormulateGrouping',
  props: {
    context: {
      type: Object,
      required: true
    }
  },
  provide () {
    return {
      isSubField: () => true,
      registerProvider: this.registerProvider,
      deregisterProvider: this.deregisterProvider
    }
  },
  data () {
    return {
      providers: [],
      keys: []
    }
  },
  inject: ['formulateRegisterRule', 'formulateRemoveRule'],
  computed: {
    items () {
      if (Array.isArray(this.context.model)) {
        if (!this.context.repeatable && this.context.model.length === 0) {
          // This is the default input.
          return [this.setId({}, 0)]
        }
        if (this.context.model.length < this.context.minimum) {
          return (new Array(this.context.minimum || 1)).fill('')
            .map((t, index) => this.setId(this.context.model[index] || {}, index))
        }
        return this.context.model.map((item, index) => this.setId(item, index))
      }
      // This is an unset group
      return (new Array(this.context.minimum || 1)).fill('').map((_i, index) => this.setId({}, index))
    },
    formShouldShowErrors () {
      return this.context.formShouldShowErrors
    },
    groupErrors () {
      return this.items
        .map((item, index) => has(this.context.groupErrors, index) ? this.context.groupErrors[index] : {})
    }
  },
  watch: {
    providers () {
      if (this.formShouldShowErrors) {
        this.showErrors()
      }
    },
    formShouldShowErrors (val) {
      if (val) {
        this.showErrors()
      }
    },
    items: {
      handler (items, oldItems) {
        if (!equals(items, oldItems, true)) {
          this.keys = items.map(item => item.__id)
        }
      },
      immediate: true
    }
  },
  created () {
    // We register with an error message of 'true' which causes the validation to fail but no message output.
    this.formulateRegisterRule(this.validateGroup.bind(this), [], 'formulateGrouping', true)
  },
  destroyed () {
    this.formulateRemoveRule('formulateGrouping')
  },
  methods: {
    validateGroup () {
      return Promise.all(this.providers.reduce((resolvers, provider) => {
        if (provider && typeof provider.hasValidationErrors === 'function') {
          resolvers.push(provider.hasValidationErrors())
        }
        return resolvers
      }, [])).then(providersHasErrors => !providersHasErrors.some(hasErrors => !!hasErrors))
    },
    showErrors () {
      this.providers.forEach(p => p && typeof p.showErrors === 'function' && p.showErrors())
    },
    setItem (index, groupProxy) {
      // Note: value must have an __id to use this function
      if (Array.isArray(this.context.model) && this.context.model.length >= this.context.minimum && !this.context.model.__init) {
        this.context.model.splice(index, 1, this.setId(groupProxy, index))
      } else {
        this.context.model = this.items.map((item, i) => i === index ? this.setId(groupProxy, index) : item)
      }
    },
    removeItem (index) {
      if (Array.isArray(this.context.model) && this.context.model.length > this.context.minimum) {
        // In this context we actually have data
        this.context.model = this.context.model.filter((item, i) => i === index ? false : item)
        this.context.rootEmit('repeatableRemoved', this.context.model)
      } else if (!Array.isArray(this.context.model) && this.items.length > this.context.minimum) {
        // In this context the fields have never been touched (not "dirty")
        this.context.model = (new Array(this.items.length - 1)).fill('').map((_i, idx) => this.setId({}, idx))
        this.context.rootEmit('repeatableRemoved', this.context.model)
      }
      // Otherwise, do nothing, we're at our minimum
    },
    registerProvider (provider) {
      if (!this.providers.some(p => p === provider)) {
        this.providers.push(provider)
      }
    },
    deregisterProvider (provider) {
      this.providers = this.providers.filter(p => p !== provider)
    },
    setId (item, index) {
      return item.__id ? item : setId(item, this.keys[index])
    }
  }
}
</script>
