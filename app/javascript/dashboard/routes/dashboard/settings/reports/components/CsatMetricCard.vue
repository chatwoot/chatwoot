<template>
  <div class="medium-2 small-6 csat--metric-card">
    <h3 class="heading">
      <span>{{ label }}</span>
      <i v-tooltip="infoText" class="csat--icon ion-ios-information" />
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
  },
};
</script>
<style lang="scss" scoped>
.csat--metric-card {
  margin: 0;
  padding: var(--space-normal) var(--space-small) var(--space-normal)
    var(--space-two);

  .heading {
    color: var(--color-heading);
    font-size: var(--font-size-small);
    font-weight: var(--font-weight-bold);
    margin: 0;
  }

  .metric {
    font-size: var(--font-size-bigger);
    font-weight: var(--font-weight-feather);
    margin-bottom: 0;
    margin-top: var(--space-smaller);
  }
}

.csat--icon {
  color: var(--b-400);
  margin-left: var(--space-micro);
}
</style>
