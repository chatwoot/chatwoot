<script lang="ts" setup>
import { ref } from 'vue'
import HstButtonGroup from './HstButtonGroup.vue'

const options = {
  slow: 'Slow',
  fast: 'Fast',
  max: 'Max',
}

const flatOptions = Object.keys(options)

const objectOptions = Object.keys(options).map(key => ({
  label: options[key],
  value: key,
}))

function initState() {
  return {
    speed: flatOptions[0],
  }
}

const count = ref('0')
</script>

<template>
  <Story
    title="HstButtonGroup"
    group="controls"
    :layout="{ type: 'single', iframe: false }"
  >
    <Variant
      title="playground"
      :init-state="initState"
    >
      <template #default="{ state }">
        <pre>{{ { speed: state.speed } }}</pre>
        <HstButtonGroup
          v-model="state.speed"
          title="Label"
          :options="objectOptions"
        />
      </template>

      <template #controls="{ state }">
        <HstButtonGroup
          v-model="state.speed"
          title="Label"
          :options="objectOptions"
        />
      </template>
    </Variant>

    <Variant
      title="Object options"
      :init-state="initState"
    >
      <template #default="{ state }">
        <pre>{{ { speed: state.speed } }}</pre>
        <HstButtonGroup
          v-model="state.speed"
          title="Label"
          :options="options"
        />
      </template>
    </Variant>

    <Variant
      title="Should retain order"
    >
      <pre>{{ { count } }}</pre>
      <HstButtonGroup
        v-model="count"
        :options="[{ label: 'Low', value: '-25' }, { label: 'Regular', value: '0' }, { label: 'High', value: '200' }]"
      />
    </Variant>
  </Story>
</template>
