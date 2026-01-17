<script lang="ts" setup>
import { reactive } from 'vue'
import HstColorSelect from './HstColorSelect.vue'

const state = reactive({
  value: '#000000',
})
</script>

<template>
  <Story
    title="HstColorSelect"
    group="controls"
    :layout="{ type: 'single', iframe: false }"
  >
    <HstColorSelect
      v-model="state.value"
      title="Color Select"
    />
    <pre>{{ state }}</pre>
    <template #controls>
      <HstColorSelect
        v-model="state.value"
        title="Value"
      />
    </template>
  </Story>
</template>
