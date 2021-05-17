<template>
  <woot-button
    variant="hollow"
    size="tiny"
    icon="ion-plus-round"
    color-scheme="secondary"
    class-names="button-wrap"
    @click="toggleLabels"
  >
    {{ $t('CONTACT_PANEL.LABELS.MODAL.ADD_BUTTON') }}
  </woot-button>
</template>

<script>
export default {
  methods: {
    toggleLabels() {
      this.$emit('add');
    },
  },
};
</script>

<style lang="scss" scoped>
.button-wrap {
  padding: var(--space-micro) var(--space-small);
  display: inline;
  line-height: 1.2;

  &::v-deep .icon {
    font-size: var(--font-size-mini);
  }
}
</style>
