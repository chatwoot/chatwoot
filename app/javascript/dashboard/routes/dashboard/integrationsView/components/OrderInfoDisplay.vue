<script setup>
defineProps({
  title: {
    type: String,
  },
  label: {
    type: String,
  },
  value: {
    type: String,
  },
  infoText: {
    type: String,
  },
  disabled: {
    type: Boolean,
  },
});
</script>
<template>
  <div
    ref="OrderInfoContainer"
    class="m-0"
    :class="{
      'grayscale pointer-events-none opacity-30': disabled,
    }"
  >
    <h3
      class="flex items-center text-sm font-medium m-0 text-slate-800 dark:text-slate-100"
    >
      <span ref="OrderInfoLabel">{{ label }}</span>
      <fluent-icon
        v-if="infoText"
        ref="OrderInfoInfo"
        v-tooltip="infoText"
        size="14"
        icon="info"
        class="text-slate-500 dark:text-slate-200 my-0 mx-1 mt-0.5"
      />
    </h3>
    <h4
      ref="OrderInfoValue"
      class="text-slate-700 dark:text-slate-100 mb-0 mt-1 font-thin text-xl max-w-lg"
    >
      {{ value }}
    </h4>
  </div>
</template>
