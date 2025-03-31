<script lang="ts" setup>
import { Dropdown as VDropdown } from 'floating-vue'
import type { ComputedRef } from 'vue'
import { computed } from 'vue'
import { Icon } from '@iconify/vue'

const props = defineProps<{
  modelValue: string
  options: Record<string, string> | Array<string>
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: string): void
  (e: 'select', value: string): void
}>()

const formattedOptions: ComputedRef<Record<string, string>> = computed(() => {
  if (Array.isArray(props.options)) {
    return Object.fromEntries(props.options.map(value => [value, value]))
  }
  return props.options
})

const selectedLabel = computed(() => formattedOptions.value[props.modelValue])

function selectValue(value: string, hide: () => void) {
  emit('update:modelValue', value)
  emit('select', value)
  hide()
}
</script>

<template>
  <VDropdown
    class="histoire-base-select"
    auto-size
    auto-boundary-max-size
  >
    <div
      class="htw-cursor-pointer htw-w-full htw-outline-none htw-px-2 htw-h-[27px] -htw-my-1 htw-border htw-border-solid htw-border-black/25 dark:htw-border-white/25 hover:htw-border-primary-500 dark:hover:htw-border-primary-500 htw-rounded-sm htw-flex htw-gap-2 htw-items-center htw-leading-normal"
    >
      <div class="htw-flex-1 htw-truncate">
        <slot :label="selectedLabel">
          {{ selectedLabel }}
        </slot>
      </div>
      <Icon
        icon="carbon:chevron-sort"
        class="htw-w-4 htw-h-4 htw-flex-none htw-ml-auto"
      />
    </div>
    <template #popper="{ hide }">
      <div class="htw-flex htw-flex-col htw-bg-gray-50 dark:htw-bg-gray-700">
        <div
          v-for="(label, value) in formattedOptions"
          v-bind="{ ...$attrs, class: null, style: null }"
          :key="label"
          class="htw-px-2 htw-py-1 htw-cursor-pointer hover:htw-bg-primary-100 dark:hover:htw-bg-primary-700"
          :class="{
            'htw-bg-primary-200 dark:htw-bg-primary-800': props.modelValue === value,
          }"
          @click="selectValue(value, hide)"
        >
          <slot
            name="option"
            :label="label"
            :value="value"
          >
            {{ label }}
          </slot>
        </div>
      </div>
    </template>
  </VDropdown>
</template>
