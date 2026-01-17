<script lang="ts" setup>
import HstTokenGrid from './HstTokenGrid.vue'

const tokens = {
  'sm': 'filter: drop-shadow(0 1px 1px rgb(0 0 0 / 0.05))',
  'DEFAULT': 'filter: drop-shadow(0 1px 2px rgb(0 0 0 / 0.1)) drop-shadow(0 1px 1px rgb(0 0 0 / 0.06))',
  'md': 'filter: drop-shadow(0 4px 3px rgb(0 0 0 / 0.07)) drop-shadow(0 2px 2px rgb(0 0 0 / 0.06))',
  'lg': 'filter: drop-shadow(0 10px 8px rgb(0 0 0 / 0.04)) drop-shadow(0 4px 3px rgb(0 0 0 / 0.1))',
  'xl': 'filter: drop-shadow(0 20px 13px rgb(0 0 0 / 0.03)) drop-shadow(0 8px 5px rgb(0 0 0 / 0.08))',
  '2xl': 'filter: drop-shadow(0 25px 25px rgb(0 0 0 / 0.15))',
  'none': 'filter: drop-shadow(0 0 #0000)',
}
</script>

<template>
  <Story
    title="HstTokenGrid"
    group="design-system"
    responsive-disabled
  >
    <Variant title="default">
      <HstTokenGrid
        :tokens="tokens"
        :get-name="key => key === 'DEFAULT' ? 'drop-shadow' : `drop-shadow-${key}`"
        :col-size="160"
      >
        <template #default="{ token }">
          <div
            class="htw-w-32 htw-h-32 htw-bg-white dark:htw-bg-black htw-rounded htw-mb-2"
            :style="token.value"
          />
        </template>
      </HstTokenGrid>
    </Variant>
  </Story>
</template>
