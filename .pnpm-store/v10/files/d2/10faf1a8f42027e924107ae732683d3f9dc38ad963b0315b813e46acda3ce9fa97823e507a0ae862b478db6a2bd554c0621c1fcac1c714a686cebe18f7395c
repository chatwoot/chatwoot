<script lang="ts">
export default {
  name: 'HstSelect',
}
</script>

<script lang="ts" setup>
import HstWrapper from '../HstWrapper.vue'
import type { HstControlOption } from '../../types'
import CustomSelect from './CustomSelect.vue'

defineProps<{
  title?: string
  modelValue?: any
  options: Record<string, any> | string[] | HstControlOption[]
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: any): void
}>()
</script>

<template>
  <HstWrapper
    :title="title"
    class="histoire-select htw-cursor-text htw-items-center"
    :class="$attrs.class"
    :style="$attrs.style"
  >
    <CustomSelect
      :options="options"
      :model-value="modelValue"
      @update:model-value="emit('update:modelValue', $event)"
    />

    <template #actions>
      <slot name="actions" />
    </template>
  </HstWrapper>
</template>
