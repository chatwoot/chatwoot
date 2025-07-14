<script lang="ts" setup>
import { computed } from 'vue'
import { HstCheckbox, HstJson, HstNumber, HstText } from '@histoire/controls'
import type { Variant } from '../../types'

const props = defineProps<{
  variant: Variant
  item: string
}>()

const comp = computed(() => {
  switch (typeof props.variant.state[props.item]) {
    case 'string':
      return HstText
    case 'number':
      return HstNumber
    case 'boolean':
      return HstCheckbox
    case 'object':
    default:
      return HstJson
  }
})

const model = computed({
  get: () => {
    return props.variant.state[props.item]
  },
  set: (value) => {
    // eslint-disable-next-line vue/no-mutating-props
    props.variant.state[props.item] = value
  },
})
</script>

<template>
  <component
    :is="comp"
    v-if="comp"
    v-model="model"
    class="histoire-controls-component-prop-item"
    :title="props.item"
  />
</template>
