<script lang="ts" setup>
import { computed, ref, watch } from 'vue'

const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false,
  },
})

const emit = defineEmits({
  'update:modelValue': (_newValue: boolean) => true,
})

function toggle() {
  emit('update:modelValue', !props.modelValue)
  animationEnabled.value = true
}

// SVG check

const path = ref<SVGPathElement>()
const dasharray = ref(0)
const progress = computed(() => props.modelValue ? 1 : 0)
const dashoffset = computed(() => (1 - progress.value) * dasharray.value)
const animationEnabled = ref(false)

watch(path, () => {
  dasharray.value = path.value.getTotalLength?.() ?? 21.21
})
</script>

<template>
  <div
    role="checkbox"
    tabindex="0"
    class="histoire-base-checkbox htw-flex htw-items-center htw-gap-2 htw-select-none htw-px-4 htw-py-3 htw-cursor-pointer hover:htw-bg-primary-100 dark:hover:htw-bg-primary-700"
    @click="toggle()"
    @keydown.enter.prevent="toggle()"
    @keydown.space.prevent="toggle()"
  >
    <div class="htw-text-white htw-w-[16px] htw-h-[16px] htw-relative">
      <div
        class="htw-border group-active:htw-bg-gray-500/20 htw-rounded-sm htw-box-border htw-absolute htw-inset-0 htw-transition-border htw-duration-150 htw-ease-out"
        :class="[
          modelValue
            ? 'htw-border-primary-500 htw-border-8'
            : 'htw-border-black/25 dark:htw-border-white/25 htw-delay-150',
        ]"
      />
      <svg
        width="16"
        height="16"
        viewBox="0 0 24 24"
        class="htw-relative htw-z-10"
      >
        <path
          ref="path"
          d="m 4 12 l 5 5 l 10 -10"
          fill="none"
          class="htw-stroke-white htw-stroke-2 htw-duration-200 htw-ease-in-out"
          :class="[
            animationEnabled ? 'htw-transition-all' : 'htw-transition-none',
            {
              'htw-delay-150': modelValue,
            },
          ]"
          :stroke-dasharray="dasharray"
          :stroke-dashoffset="dashoffset"
        />
      </svg>
    </div>

    <slot />
  </div>
</template>
