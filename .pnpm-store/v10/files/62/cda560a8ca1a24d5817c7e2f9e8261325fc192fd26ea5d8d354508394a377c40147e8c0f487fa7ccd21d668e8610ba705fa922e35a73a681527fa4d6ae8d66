<script lang="ts" setup>
import { computed } from 'vue'
import { Icon } from '@iconify/vue'
import type { AutoPropComponentDefinition, PropDefinition } from '@histoire/shared'
import { HstCheckbox, HstJson, HstNumber, HstText } from '@histoire/controls'
import type { Variant } from '../../types'

const props = defineProps<{
  variant: Variant
  component: AutoPropComponentDefinition
  definition: PropDefinition
}>()

const comp = computed(() => {
  switch (props.definition.types?.[0]) {
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
    return props.variant.state._hPropState[props.component.index]?.[props.definition.name]
  },
  set: (value) => {
    if (!props.variant.state._hPropState[props.component.index]) {
      // eslint-disable-next-line vue/no-mutating-props
      props.variant.state._hPropState[props.component.index] = {}
    }
    // eslint-disable-next-line vue/no-mutating-props
    props.variant.state._hPropState[props.component.index][props.definition.name] = value
  },
})

function reset() {
  if (props.variant.state._hPropState[props.component.index]) {
    // eslint-disable-next-line vue/no-mutating-props
    delete props.variant.state._hPropState[props.component.index][props.definition.name]
  }
}

const canReset = computed(() => props.variant.state?._hPropState?.[props.component.index] && props.definition.name in props.variant.state._hPropState[props.component.index])
</script>

<template>
  <component
    :is="comp"
    v-if="comp"
    v-model="model"
    :placeholder="model === undefined ? definition?.default : null"
    class="histoire-controls-component-prop-item"
    :title="`${definition.name}${canReset ? ' *' : ''}`"
  >
    <template #actions>
      <Icon
        v-tooltip="'Remove override'"
        icon="carbon:erase"
        class="htw-cursor-pointer htw-w-4 htw-h-4 hover:htw-text-primary-500 dark:hover:htw-text-primary-400 htw-text-gray-900 dark:htw-text-gray-100"
        :class="[
          canReset ? 'htw-opacity-50 hover:htw-opacity-100' : 'htw-opacity-25 htw-pointer-events-none',
        ]"
        @click.stop="reset()"
      />
    </template>
  </component>
</template>
