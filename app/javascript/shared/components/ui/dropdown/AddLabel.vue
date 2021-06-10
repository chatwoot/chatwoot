<template>
  <woot-button variant="link" class="label--add" @click="addLabel">
    <woot-label
      color-scheme="secondary"
      :title="$t('CONTACT_PANEL.LABELS.CONVERSATION.ADD_BUTTON')"
      icon="ion-plus-round"
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
  &::v-deep .label {
    cursor: pointer;
    background: transparent;
    border-color: var(--s-700);
    margin: 0;

    &:hover {
      background: var(--s-50);
    }
  }
}
</style>
