<template>
  <div class="conv-details--item">
    <h4 class="conv-details--item__label">
      <div>
        <i v-if="icon" :class="icon" class="conv-details--item__icon"></i>
        {{ title }}
      </div>
      <button v-if="showEdit" @click="onEdit">
        {{ $t('CONTACT_PANEL.EDIT_LABEL') }}
      </button>
    </h4>
    <div v-if="value" class="conv-details--item__value">
      {{ value }}
    </div>
  </div>
</template>

<script>
export default {
  props: {
    title: { type: String, required: true },
    icon: { type: String, default: '' },
    value: { type: [String, Number], default: '' },
    showEdit: { type: Boolean, default: false },
  },
  methods: {
    onEdit() {
      this.$emit('edit');
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/variables';
@import '~dashboard/assets/scss/mixins';

.conv-details--item {
  padding-bottom: var(--space-slab);

  &:last-child {
    padding-bottom: 0;
  }

  .conv-details--item__label {
    align-items: center;
    display: flex;
    font-size: $font-size-small;
    font-weight: $font-weight-medium;
    justify-content: space-between;
    margin-bottom: $space-micro;

    button {
      cursor: pointer;
      color: $color-body;
    }
  }

  .conv-details--item__value {
    word-break: break-all;
    margin-top: $space-small;
  }
}
</style>
