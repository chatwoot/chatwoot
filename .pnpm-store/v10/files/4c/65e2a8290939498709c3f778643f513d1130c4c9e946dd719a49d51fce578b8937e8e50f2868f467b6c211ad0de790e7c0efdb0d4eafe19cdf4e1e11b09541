<script lang="ts" setup>
import HstNumber from './HstNumber.vue'

function initState() {
  return {
    count: 20,
    step: 1,
  }
}
</script>

<template>
  <Story
    title="HstNumber"
    group="controls"
  >
    <Variant
      title="default"
      :init-state="initState"
    >
      <template #default="{ state }">
        <HstNumber
          v-model="state.count"
          :step="state.step"
          title="Count"
        />
      </template>

      <template #controls="{ state }">
        <HstNumber
          v-model="state.count"
          title="Count"
        />

        <HstNumber
          v-model="state.step"
          title="Step"
        />
      </template>
    </Variant>
  </Story>
</template>
