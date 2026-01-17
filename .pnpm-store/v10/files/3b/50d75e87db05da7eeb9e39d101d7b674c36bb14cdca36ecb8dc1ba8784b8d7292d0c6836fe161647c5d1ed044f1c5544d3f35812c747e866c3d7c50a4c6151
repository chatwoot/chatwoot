<script lang="ts" setup>
import HstJson from './HstJson.vue'

function initState() {
  return {
    film: {
      year: 2017,
      title: 'Blade Runner 2049',
      actors: ['Ryan Gosling', 'Harrison Ford', 'Ana de Armas', 'Sylvia Hoeks'],
    },
  }
}
</script>

<template>
  <Story
    title="HstJson"
    group="controls"
    :layout="{ type: 'single', iframe: false }"
  >
    <Variant
      title="default"
      :init-state="initState"
    >
      <template #default="{ state }">
        <HstJson
          v-model="state.film"
          title="Textarea"
        />
        <pre>{{ state.film }}</pre>
      </template>

      <template #controls="{ state }">
        <HstJson
          v-model="state.film"
          title="Text"
        />
      </template>
    </Variant>
  </Story>
</template>
