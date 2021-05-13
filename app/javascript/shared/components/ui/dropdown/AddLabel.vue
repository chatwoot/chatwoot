<template>
  <div>
    <woot-button
      variant="hollow"
      size="tiny"
      icon="ion-plus-round"
      color-scheme="secondary"
      @click="toggleLabels"
    >
      {{ $t('CONTACT_PANEL.LABELS.MODAL.ADD_BUTTON') }}
    </woot-button>
  </div>
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

<style lang="scss" scoped></style>
