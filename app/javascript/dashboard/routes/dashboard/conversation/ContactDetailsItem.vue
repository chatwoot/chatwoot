<template>
  <div class="conv-details--item" :class="{ compact: compact }">
    <h4 class="conv-details--item__label text-block-title">
      <span class="item__title">
        {{ title }}
      </span>
      <slot name="button" />
    </h4>
    <div v-if="value" class="conv-details--item__value">
      <slot>
        {{ value }}
      </slot>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    title: { type: String, required: true },
    icon: { type: String, default: '' },
    emoji: { type: String, default: '' },
    value: { type: [String, Number], default: '' },
    compact: { type: Boolean, default: false },
  },
};
</script>

<style lang="scss" scoped>
.conv-details--item {
  overflow: auto;
  padding: var(--space-slab) var(--space-normal);

  &.compact {
    padding: 0;
  }

  .conv-details--item__label {
    align-items: center;
    display: flex;
    justify-content: space-between;

    .edit-button {
      padding: 0;
    }
  }

  .conv-details--item__value {
    word-break: break-all;
  }
}
</style>
