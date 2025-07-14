<script lang="ts" setup>
import { Icon } from '@iconify/vue'
import BaseIcon from '../base/BaseIcon.vue'
import type { SearchResult } from '../../types.js'

defineProps<{
  result: SearchResult
  selected: boolean
}>()

const defaultIcons = {
  story: 'carbon:cube',
  variant: 'carbon:cube',
}

const kindLabels = {
  story: 'Story',
  variant: 'Variant',
  command: 'Command',
}
</script>

<template>
  <BaseIcon
    :icon="result.icon ?? defaultIcons[result.kind]"
    class="htw-w-4 htw-h-4"
    :class="[
      !selected ? [
        result.iconColor
          ? 'bind-icon-color'
          : {
            'htw-text-primary-500': result.kind === 'story',
            'htw-text-gray-500': result.kind === 'variant',
          },
      ] : [],
      {
        'colorize-black': selected,
      },
    ]"
  />
  <div class="htw-flex-1">
    <div class="htw-flex">
      {{ result.title }}
      <span class="htw-ml-auto htw-opacity-40">
        {{ kindLabels[result.kind] }}
      </span>
    </div>

    <div
      v-if="result.path?.length"
      class="htw-flex htw-items-center htw-gap-0.5 htw-opacity-60"
    >
      <div
        v-for="(p, index) of result.path"
        :key="index"
        class="htw-flex htw-items-center htw-gap-0.5"
      >
        <Icon
          v-if="index > 0"
          icon="carbon:chevron-right"
          class="htw-w-4 htw-h-4 htw-mt-0.5 htw-opacity-50"
        />
        <span>{{ p }}</span>
      </div>
    </div>
  </div>
</template>
