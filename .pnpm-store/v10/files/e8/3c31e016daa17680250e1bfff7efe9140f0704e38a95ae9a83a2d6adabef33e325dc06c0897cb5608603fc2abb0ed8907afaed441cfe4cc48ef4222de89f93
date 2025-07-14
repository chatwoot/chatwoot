<script lang="ts" setup>
import type { AutoPropComponentDefinition } from '@histoire/shared'
import { Icon } from '@iconify/vue'
import type { Variant } from '../../types'
import ControlsComponentPropItem from './ControlsComponentPropItem.vue'

defineProps<{
  variant: Variant
  definition: AutoPropComponentDefinition
}>()
</script>

<template>
  <div class="histoire-controls-component-props">
    <div class="htw-font-mono htw-p-2 htw-flex htw-items-center htw-gap-1">
      <Icon
        v-tooltip="'Auto-detected props'"
        icon="carbon:flash"
        class="htw-w-4 htw-h-4 htw-text-primary-500 htw-flex-none"
      />
      <div>
        <span class="htw-opacity-30">&lt;</span>{{ definition.name }}<span class="htw-opacity-30">&gt;</span>
      </div>
    </div>

    <ControlsComponentPropItem
      v-for="prop of definition.props"
      :key="prop.name"
      :variant="variant"
      :component="definition"
      :definition="prop"
    />
  </div>
</template>
