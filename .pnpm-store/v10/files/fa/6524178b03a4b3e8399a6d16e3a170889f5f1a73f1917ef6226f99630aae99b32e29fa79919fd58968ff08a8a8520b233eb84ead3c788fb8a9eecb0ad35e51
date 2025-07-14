<script lang="ts">
export default {
  name: 'CustomSelect',
}
</script>

<script lang="ts" setup>
import { Dropdown as VDropdown } from 'floating-vue'
import type { ComputedRef } from 'vue'
import { computed } from 'vue'
import { Icon } from '@iconify/vue'
import type { HstControlOption } from '../../types'

const props = defineProps<{
  modelValue: string
  options: Record<string, any> | string[] | number[] | HstControlOption[]
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: string): void
}>()

const formattedOptions: ComputedRef<[any, string][]> = computed(() => {
  if (Array.isArray(props.options)) {
    return props.options.map((option) => {
      if (typeof option === 'string' || typeof option === 'number') {
        return [option, String(option)] as [any, string]
      }
      else {
        return [option.value, option.label] as [any, string]
      }
    })
  }
  else {
    return Object.entries(props.options)
  }
})

const selectedLabel = computed(() => formattedOptions.value.find(([value]) => value === props.modelValue)?.[1])

function selectValue(value: any, hide: () => void) {
  emit('update:modelValue', value)
  hide()
}
</script>

<template>
  <VDropdown
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
          v-for="[value, label] of formattedOptions"
          v-bind="{ ...$attrs, class: null, style: null }"
          :key="label"
          class="htw-px-2 htw-py-1 htw-cursor-pointer hover:htw-bg-primary-100 dark:hover:htw-bg-primary-700"
          :class="{
            'htw-bg-primary-200 dark:htw-bg-primary-800': props.modelValue === value,
          }"
          @click="selectValue(value, hide)"
        >
          {{ label }}
        </div>
      </div>
    </template>
  </VDropdown>
</template>

<style lang="postcss">
/* @TODO custom themes */

.v-popper {
  line-height: 0;
}

.v-popper--theme-dropdown {
  .htw-dark & {
    .v-popper__inner {
      @apply htw-bg-gray-700 htw-border-gray-850 htw-text-gray-100;
    }

    .v-popper__arrow-inner {
      @apply htw-border-gray-700;
    }

    .v-popper__arrow-outer {
      @apply htw-border-gray-850;
    }
  }

  &.v-popper__popper--show-from .v-popper__wrapper {
    transform: scale(.75);
  }

  &.v-popper__popper--show-to .v-popper__wrapper {
    transform: none;
    transition: transform .15s cubic-bezier(0, 1, .5, 1);
  }
}

.v-popper__popper:focus-visible {
  outline: none;
}
</style>
