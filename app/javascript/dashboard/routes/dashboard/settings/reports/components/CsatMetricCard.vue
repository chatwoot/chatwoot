<template>
  <div
    class="md:w-[16%] sm:w-[50%] sm:max-w-[50%] md:max-w-[16%] csat--metric-card"
    :class="{
      disabled: disabled,
    }"
  >
    <h3 class="heading">
      <span>{{ label }}</span>
      <fluent-icon
        v-tooltip="infoText"
        size="14"
        icon="info"
        class="csat--icon"
      />
    </h3>
    <h4 class="metric">
      {{ value }}
    </h4>
  </div>
</template>
<script>
export default {
  props: {
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
  },
};
</script>
<style lang="scss" scoped>
.csat--metric-card {
  margin: 0;
  padding: var(--space-normal);

  &.disabled {
    // grayscale everything
    filter: grayscale(100%);
    opacity: 0.3;
    pointer-events: none;
  }

  .heading {
    align-items: center;
    display: flex;
    font-size: var(--font-size-small);
    font-weight: var(--font-weight-bold);
    margin: 0;
    @apply text-slate-800 dark:text-slate-100;
  }

  .metric {
    font-size: var(--font-size-bigger);
    font-weight: var(--font-weight-feather);
    margin-bottom: 0;
    margin-top: var(--space-smaller);
    @apply text-slate-700 dark:text-slate-100;
  }
}

.csat--icon {
  @apply text-slate-500 dark:text-slate-200 my-0 mx-0.5;
}
</style>
