<script lang="ts" setup>
import HstCheckboxList from './HstCheckboxList.vue'

const options = {
  'crash-bandicoot': 'Crash Bandicoot',
  'the-last-of-us': 'The Last of Us',
  'ghost-of-tsushima': 'Ghost of Tsushima',
}

const objectOptions = Object.keys(options).map(key => ({
  label: options[key],
  value: key,
}))

function initState() {
  return {
    characters: [],
  }
}
</script>

<template>
  <Story
    title="HstCheckboxList"
    group="controls"
    :layout="{ type: 'single', iframe: false }"
  >
    <Variant
      title="playground"
      :init-state="initState"
    >
      <template #default="{ state }">
        <HstCheckboxList
          v-model="state.characters"
          title="Label"
          :options="objectOptions"
        />
      </template>

      <template #controls="{ state }">
        <HstCheckboxList
          v-model="state.characters"
          title="Label"
          :options="objectOptions"
        />
      </template>
    </Variant>
  </Story>
</template>
