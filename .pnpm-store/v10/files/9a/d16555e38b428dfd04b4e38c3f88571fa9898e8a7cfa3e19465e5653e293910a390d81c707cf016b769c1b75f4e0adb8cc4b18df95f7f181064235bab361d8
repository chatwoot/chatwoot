<script lang="ts">
export default {
  name: 'HstRadio',
}
</script>

<script lang="ts" setup>
import type { ComputedRef } from 'vue'
import { computed, ref } from 'vue'
import HstWrapper from '../HstWrapper.vue'
import type { HstControlOption } from '../../types'

const props = defineProps<{
  title?: string
  modelValue?: string
  options: HstControlOption[]
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
  (e: 'update:modelValue', value: string): void
}>()

function selectOption(value: string) {
  emit('update:modelValue', value)
  animationEnabled.value = true
}

// animationEnabled prevents the animation from triggering on mounted
const animationEnabled = ref(false)
</script>

<template>
  <HstWrapper
    role="group"
    :title="title"
    class="histoire-radio htw-cursor-text"
    :class="$attrs.class"
    :style="$attrs.style"
  >
    <div class="-htw-my-1">
      <template
        v-for="(label, value) in formattedOptions"
        :key="value"
      >
        <input
          :id="`${value}-radio_${title}`"
          type="radio"
          :name="`${value}-radio_${title}`"
          :value="value"
          :checked="value === modelValue"
          class="!htw-hidden"
          @change="selectOption(value)"
        >
        <label
          tabindex="0"
          :for="`${value}-radio_${title}`"
          class="htw-cursor-pointer htw-flex htw-items-center htw-relative htw-py-1 htw-group"
          @keydown.enter.prevent="selectOption(value)"
          @keydown.space.prevent="selectOption(value)"
        >
          <svg
            width="16"
            height="16"
            viewBox="-12 -12 24 24"
            class="htw-relative htw-z-10 htw-border htw-border-solid  htw-text-inherit htw-rounded-full htw-box-border htw-inset-0 htw-transition-border htw-duration-150 htw-ease-out htw-mr-2 group-hover:htw-border-primary-500"
            :class="[
              modelValue === value
                ? 'htw-border-primary-500'
                : 'htw-border-black/25 dark:htw-border-white/25',
            ]"
          >
            <circle
              r="7"
              class="htw-will-change-transform"
              :class="[
                animationEnabled ? 'htw-transition-all' : 'htw-transition-none',
                {
                  'htw-delay-150': modelValue === value,
                },
                modelValue === value
                  ? 'htw-fill-primary-500'
                  : 'htw-fill-transparent htw-scale-0',
              ]"
            />
          </svg>
          {{ label }}
        </label>
      </template>
    </div>

    <template #actions>
      <slot name="actions" />
    </template>
  </HstWrapper>
</template>
