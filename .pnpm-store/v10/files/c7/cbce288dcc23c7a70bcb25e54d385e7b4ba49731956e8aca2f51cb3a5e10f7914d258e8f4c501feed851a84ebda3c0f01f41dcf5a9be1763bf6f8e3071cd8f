<script lang="ts" setup>
import { reactive } from 'vue'
import HstSlider from './HstSlider.vue'

const state = reactive({
  value: 20,
  min: 0,
  max: 100,
  step: 5,
})
</script>

<template>
  <Story
    title="HstSlider"
    group="controls"
    :layout="{ type: 'single', iframe: false }"
  >
    <HstSlider
      v-model="state.value"
      :step="state.step"
      :min="state.min"
      :max="state.max"
      title="Slide"
    />
    <pre>{{ state }}</pre>
    <template #controls>
      <HstSlider
        v-model="state.value"
        :step="state.step"
        :min="state.min"
        :max="state.max"
        title="Value"
      />
    </template>
  </Story>
</template>
