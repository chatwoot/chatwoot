<template>
  <FormulateSlot
    name="repeatable"
    :context="context"
    :index="index"
    :remove-item="removeItem"
  >
    <component
      :is="context.slotComponents.repeatable"
      :context="context"
      :index="index"
      :remove-item="removeItem"
      v-bind="context.slotProps.repeatable"
    >
      <FormulateSlot
        :context="context"
        :index="index"
        name="default"
      />
    </component>
  </FormulateSlot>
</template>

<script>
import { equals } from './libs/utils'
import useRegistry, { useRegistryComputed, useRegistryMethods, useRegistryProviders, useRegistryWatchers } from './libs/registry'

export default {
  provide () {
    return {
      ...useRegistryProviders(this, ['getFormValues']),
      formulateSetter: (field, value) => this.setGroupValue(field, value)
    }
  },
  inject: {
    registerProvider: 'registerProvider',
    deregisterProvider: 'deregisterProvider'
  },
  props: {
    index: {
      type: Number,
      required: true
    },
    context: {
      type: Object,
      required: true
    },
    uuid: {
      type: String,
      required: true
    },
    errors: {
      type: Object,
      required: true
    }
  },
  data () {
    return {
      ...useRegistry(this),
      isGrouping: true
    }
  },
  computed: {
    ...useRegistryComputed(),
    mergedFieldErrors () {
      return this.errors
    }
  },
  watch: {
    ...useRegistryWatchers(),
    'context.model': {
      handler (values) {
        if (!equals(values[this.index], this.proxy, true)) {
          this.setValues(values[this.index])
        }
      },
      deep: true
    }
  },
  created () {
    this.applyInitialValues()
    this.registerProvider(this)
  },
  beforeDestroy () {
    this.preventCleanup = true
    this.deregisterProvider(this)
  },
  methods: {
    ...useRegistryMethods(),
    setGroupValue (field, value) {
      if (!equals(this.proxy[field], value, true)) {
        this.setFieldValue(field, value)
      }
    },
    removeItem () {
      this.$emit('remove', this.index)
    }
  }
}
</script>
