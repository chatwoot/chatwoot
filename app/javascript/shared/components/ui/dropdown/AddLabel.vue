<template>
  <woot-button variant="link" class="label--add" @click="addLabel">
    <woot-label
      color-scheme="secondary"
      :title="$t('CONTACT_PANEL.LABELS.CONVERSATION.ADD_BUTTON')"
      icon="add-circle"
    />
  </woot-button>
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
  margin-bottom: var(--space-smaller);
  margin-top: var(--space-smaller);
  border: 0;

  &::v-deep .label {
    cursor: pointer;
    margin-bottom: 0;
    background: transparent;
    border: 1px solid var(--s-600);

    &:hover {
      background: var(--s-50);
    }
  }
}
</style>
