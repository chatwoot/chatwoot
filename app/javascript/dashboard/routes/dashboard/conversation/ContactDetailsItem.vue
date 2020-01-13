<template>
  <div class="conv-details--item">
    <div class="conv-details--item__label">
      <i :class="icon" class="conv-details--item__icon"></i>
      {{ title }}
    </div>
    <div v-if="value" class="conv-details--item__value">
      {{ value }}
    </div>
  </div>
</template>

<script>
export default {
  props: {
    title: { type: String, required: true },
    icon: { type: String, required: true },
    value: { type: [String, Number], default: '' },
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/variables';
@import '~dashboard/assets/scss/mixins';

.conv-details--item {
  padding-bottom: $space-normal;

  &:last-child {
    padding-bottom: 0;
  }

  .conv-details--item__icon {
    padding-right: $space-micro;
  }

  .conv-details--item__label {
    font-weight: $font-weight-medium;
    margin-bottom: $space-micro;
  }

  .conv-details--item__value {
    word-break: break-all;
  }
}
</style>
