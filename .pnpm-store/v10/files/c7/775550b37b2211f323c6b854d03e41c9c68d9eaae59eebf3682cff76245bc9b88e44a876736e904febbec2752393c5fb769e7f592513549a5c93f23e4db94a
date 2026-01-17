<script lang="ts">
export default {
  name: 'HstCheckboxList',
}
</script>

<script lang="ts" setup>
import type { ComputedRef } from 'vue'
import { computed } from 'vue'
import HstWrapper from '../HstWrapper.vue'
import type { HstControlOption } from '../../types'
import HstSimpleCheckbox from './HstSimpleCheckbox.vue'

const props = defineProps<{
  title?: string
  modelValue: Array<string>
  options: string[] | HstControlOption[]
}>()

const formattedOptions: ComputedRef<Record<string, string>> = computed(() => {
  if (Array.isArray(props.options)) {
    return Object.fromEntries(props.options.map((value: string | HstControlOption) => {
      if (typeof value === 'string') {
        return [value, value]
      }
      else {
        return [value.value, value.label]
      }
    }))
  }
  return props.options
})

const emit = defineEmits<{
  (e: 'update:modelValue', value: Array<string>): void
}>()

function toggleOption(value: string) {
  if (props.modelValue.includes(value)) {
    emit('update:modelValue', props.modelValue.filter(element => element !== value))
  }
  else {
    emit('update:modelValue', [...props.modelValue, value])
  }
}
</script>

<template>
  <HstWrapper
    role="group"
    :title="title"
    class="histoire-checkbox-list htw-cursor-text"
    :class="$attrs.class"
    :style="$attrs.style"
  >
    <div class="-htw-my-1">
      <template
        v-for="(label, value) in formattedOptions"
        :key="value"
      >
        <label
          tabindex="0"
          :for="`${value}-radio`"
          class="htw-cursor-pointer htw-flex htw-items-center htw-relative htw-py-1 htw-group"
          @keydown.enter.prevent="toggleOption(value)"
          @keydown.space.prevent="toggleOption(value)"
          @click="toggleOption(value)"
        >
          <HstSimpleCheckbox
            :model-value="modelValue.includes(value)"
            class="htw-mr-2"
          />
          {{ label }}
        </label>
      </template>
    </div>

    <template #actions>
      <slot name="actions" />
    </template>
  </HstWrapper>
</template>
