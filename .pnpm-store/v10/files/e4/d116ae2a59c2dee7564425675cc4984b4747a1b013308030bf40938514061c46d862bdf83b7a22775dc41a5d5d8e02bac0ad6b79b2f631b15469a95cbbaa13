<script lang="ts" setup>
import HstButton from './HstButton.vue'

const variants: Array<{ name: string, bind?: unknown }> = [
  { name: 'Default' },
  { name: 'Primary', bind: { color: 'primary' } },
  { name: 'Flat', bind: { color: 'flat' } },
]
</script>

<template>
  <Story
    title="HstButton"
    group="controls"
    :layout="{ type: 'grid', width: '200px', iframe: false }"
  >
    <Variant
      v-for="(variant, key) of variants"
      :key="key"
      :title="variant.name"
    >
      <HstButton
        v-bind="variant.bind as {}"
        class="htw-p-2"
      >
        Click me!
      </HstButton>
    </Variant>
  </Story>
</template>
