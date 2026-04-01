<script setup>
defineProps({
  label: {
    type: String,
    required: true,
  },
  value: {
    type: String,
    required: true,
  },
  infoText: {
    type: String,
    required: true,
  },
  disabled: {
    type: Boolean,
    default: false,
  },
});
</script>

<template>
  <div
    data-test-id="reportMetricContainer"
    :class="{
      'grayscale pointer-events-none opacity-30': disabled,
    }"
  >
    <h3
      class="flex items-center m-0 text-sm font-medium text-on-surface-variant"
    >
      <span data-test-id="reportMetricLabel">{{ label }}</span>
      <fluent-icon
        v-tooltip="infoText"
        data-test-id="reportMetricInfo"
        size="14"
        icon="info"
        class="text-on-surface-variant my-0 mx-1 mt-0.5"
      />
    </h3>
    <h4
      data-test-id="reportMetricValue"
      class="mt-1 mb-0 text-2xl text-on-surface"
    >
      {{ value }}
    </h4>
  </div>
</template>
