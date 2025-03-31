<script lang="ts">
export default {
  name: 'HstSimpleCheckbox',
}
</script>

<script setup lang="ts">
import { computed, ref, watch } from 'vue'

const props = defineProps<{
  modelValue?: boolean
  withToggle?: boolean
}>()

const emit = defineEmits({
  'update:modelValue': (newValue: boolean) => true,
})

function toggle() {
  if (!props.withToggle) {
    return
  }

  emit('update:modelValue', !props.modelValue)
}

watch(() => props.modelValue, () => {
  animationEnabled.value = true
})

// SVG check

const path = ref<SVGPathElement>()
const dasharray = ref(0)
const progress = computed(() => props.modelValue ? 1 : 0)
const dashoffset = computed(() => (1 - progress.value) * dasharray.value)

// animationEnabled prevents the animation from triggering on mounted
const animationEnabled = ref(false)

watch(path, () => {
  dasharray.value = path.value.getTotalLength?.() ?? 21.21
})
</script>

<template>
  <div
    class="histoire-simple-checkbox htw-group htw-text-white htw-w-[16px] htw-h-[16px] htw-relative"
    :class="{ 'htw-cursor-pointer': withToggle }"
    @click="toggle"
  >
    <div
      class="htw-border htw-border-solid group-active:htw-bg-gray-500/20 htw-rounded-sm htw-box-border htw-absolute htw-inset-0 htw-transition-border htw-duration-150 htw-ease-out group-hover:htw-border-primary-500 group-hover:dark:htw-border-primary-500"
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
</template>
