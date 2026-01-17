<script lang="ts">
export default {
  name: 'HstSlider',
  inheritAttrs: false,
}
</script>

<script lang="ts" setup>
import { computed, ref } from 'vue'
import type { CSSProperties } from 'vue'
import { VTooltip as vTooltip } from 'floating-vue'
import HstWrapper from '../HstWrapper.vue'

const props = defineProps<{
  title?: string
  modelValue?: number
  min: number
  max: number
}>()

const emit = defineEmits({
  'update:modelValue': (newValue: number) => true,
})

const showTooltip = ref(false)
const input = ref<HTMLInputElement>(null)

const numberModel = computed({
  get: () => props.modelValue,
  set: (value) => {
    emit('update:modelValue', value)
  },
})

const percentage = computed(() => {
  return (props.modelValue - props.min) / (props.max - props.min)
})

const tooltipStyle = computed<CSSProperties>(() => {
  const gap = 8
  if (input.value) {
    const position = gap + ((input.value.clientWidth - 2 * gap) * percentage.value)
    return {
      left: `${position}px`,
    }
  }
  return {}
})
</script>

<template>
  <HstWrapper
    class="histoire-slider htw-items-center"
    :title="title"
    :class="$attrs.class"
    :style="$attrs.style"
  >
    <div class="htw-relative htw-w-full htw-flex htw-items-center">
      <div class="htw-absolute htw-inset-0 htw-flex htw-items-center">
        <div class="htw-border htw-border-black/25 dark:htw-border-white/25 htw-h-1 htw-w-full htw-rounded-full" />
      </div>
      <input
        ref="input"
        v-model.number="numberModel"
        class="htw-range-input htw-appearance-none htw-border-0 htw-bg-transparent htw-cursor-pointer htw-relative htw-w-full htw-m-0 htw-text-gray-700"
        type="range"
        v-bind="{ ...$attrs, class: null, style: null, min, max }"
        @mouseover="showTooltip = true"
        @mouseleave="showTooltip = false"
      >
      <div
        v-if="showTooltip"
        v-tooltip="{ content: modelValue.toString(), shown: true, distance: 16, delay: 0 }"
        class="htw-absolute"
        :style="tooltipStyle"
      />
    </div>
  </HstWrapper>
</template>

<style lang="pcss">
.htw-range-input {
  &::-webkit-slider-thumb {
    @apply htw-appearance-none htw-h-3 htw-w-3 htw-bg-white dark:htw-bg-gray-700 htw-border htw-border-solid htw-border-black/25 dark:htw-border-white/25 htw-rounded-full;
  }

  &:hover::-webkit-slider-thumb {
    @apply !htw-bg-primary-500  !htw-border-primary-500;
  }
}

/* Separate rules for -moz-range-thumb to prevent a bug with Safari that causes it to ignore custom style */

.htw-range-input {
  &::-moz-range-thumb {
    @apply htw-appearance-none htw-h-3 htw-w-3 htw-bg-white dark:htw-bg-gray-700 htw-border htw-border-solid htw-border-black/25 dark:htw-border-white/25 htw-rounded-full;
  }

  &:hover::-moz-range-thumb {
    @apply !htw-bg-primary-500  !htw-border-primary-500;
  }
}
</style>
