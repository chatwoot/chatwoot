<script lang="ts" setup>
import HstRadio from './HstRadio.vue'

const options = {
  'crash-bandicoot': 'Crash Bandicoot',
  'the-last-of-us': 'The Last of Us',
  'ghost-of-tsushima': 'Ghost of Tsushima',
}

const flatOptions = Object.keys(options)

const objectOptions = Object.keys(options).map(key => ({
  label: options[key],
  value: key,
}))

function initState() {
  return {
    character: flatOptions[0],
  }
}
</script>

<template>
  <Story
    title="HstRadio"
    group="controls"
    :layout="{ type: 'single', iframe: false }"
  >
    <Variant
      title="playground"
      :init-state="initState"
    >
      <template #default="{ state }">
        <HstRadio
          v-model="state.character"
          title="Label"
          :options="objectOptions"
        />
      </template>

      <template #controls="{ state }">
        <HstRadio
          v-model="state.character"
          title="Label"
          :options="objectOptions"
        />
      </template>
    </Variant>
  </Story>
</template>
