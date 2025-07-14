<script setup lang="ts">
import { computed } from 'vue'
import { Icon } from '@iconify/vue'
import type { Variant } from '@histoire/shared'
import ControlsComponentStateItem from './ControlsComponentStateItem.vue'

const props = defineProps<{
  variant: Variant
}>()

const stateKeys = computed(() => Object.keys(props.variant.state || {})
  .filter(key => !key.startsWith('_h')))
</script>

<template>
  <div class="histoire-controls-component-init-state">
    <div class="htw-p-2 htw-flex htw-items-center htw-gap-1">
      <Icon
        v-tooltip="'Auto-detected state'"
        icon="carbon:data-vis-1"
        class="htw-w-4 htw-h-4 htw-text-primary-500 htw-flex-none"
      />
      <div>
        State
      </div>
    </div>
    <ControlsComponentStateItem
      v-for="key of stateKeys"
      :key="key"
      :item="key"
      :variant="variant"
    />
  </div>
</template>

<style scoped>

</style>
