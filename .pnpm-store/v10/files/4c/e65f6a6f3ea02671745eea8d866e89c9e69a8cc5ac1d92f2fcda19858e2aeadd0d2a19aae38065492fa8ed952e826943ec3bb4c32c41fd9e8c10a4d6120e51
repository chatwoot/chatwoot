<script lang="ts" setup>
import HstSimpleCheckbox from './HstSimpleCheckbox.vue'

function initState() {
  return {
    checked: true,
  }
}
</script>

<template>
  <Story
    title="internals/HstSimpleCheckbox"
    :layout="{ type: 'single', iframe: false }"
  >
    <Variant
      title="playground"
      :init-state="initState"
    >
      <template #default="{ state }">
        <HstSimpleCheckbox
          v-model="state.checked"
          with-toggle
        />
      </template>
    </Variant>
  </Story>
</template>
