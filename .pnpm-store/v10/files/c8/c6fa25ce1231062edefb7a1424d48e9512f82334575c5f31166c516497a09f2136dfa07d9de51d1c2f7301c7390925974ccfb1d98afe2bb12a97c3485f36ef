<script lang="ts" setup>
import HstTextarea from './HstTextarea.vue'

function initState() {
  return {
    text: '',
  }
}
</script>

<template>
  <Story
    title="HstTextarea"
    group="controls"
  >
    <Variant
      title="default"
      :init-state="initState"
    >
      <template #default="{ state }">
        <HstTextarea
          v-model="state.text"
          title="Textarea"
        />
      </template>

      <template #controls="{ state }">
        <HstTextarea
          v-model="state.text"
          title="Text"
        />
      </template>
    </Variant>
  </Story>
</template>
