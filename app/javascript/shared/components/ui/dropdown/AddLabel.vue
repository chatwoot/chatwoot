<template>
  <span role="button" class="label--add" @click="addLabel">
    <woot-label
      color-scheme="secondary"
      :title="$t('CONTACT_PANEL.LABELS.MODAL.ADD_BUTTON')"
      icon="ion-plus-round"
    />
  </span>
</template>

<script>
export default {
  methods: {
    addLabel() {
      this.$emit('add');
    },
  },
};
</script>

<style lang="scss" scoped>
.label--add {
  display: inline-block;
  &::v-deep .label {
    cursor: pointer;
    background: transparent;
    border-color: var(--s-700);

    &:hover {
      background: var(--s-50);
    }
  }
}
</style>
