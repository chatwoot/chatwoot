<script lang="ts" setup>
import HstText from './HstText.vue'

function initState() {
  return {
    label: 'My really long label',
    text: '',
  }
}
</script>

<template>
  <Story
    title="HstText"
    group="controls"
    :layout="{
      type: 'grid',
      width: '100%',
    }"
  >
    <Variant
      title="default"
      :init-state="initState"
    >
      <template #default="{ state }">
        <HstText
          v-model="state.text"
          :title="state.label"
        />
      </template>

      <template #controls="{ state }">
        <HstText
          v-model="state.label"
          title="Label"
        />
        <HstText
          v-model="state.text"
          title="Text"
        />
      </template>
    </Variant>

    <Variant
      title="no-label"
      :init-state="initState"
    >
      <template #default="{ state }">
        <HstText
          v-model="state.text"
          placeholder="Enter some text..."
        />
      </template>

      <template #controls="{ state }">
        <HstText
          v-model="state.text"
          title="Text"
        />
      </template>
    </Variant>
  </Story>
</template>
