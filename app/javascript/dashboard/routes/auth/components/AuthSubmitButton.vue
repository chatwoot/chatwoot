<template>
  <woot-button
    size="expanded"
    color-scheme="primary"
    class-names="submit--button"
    :is-disabled="isDisabled"
    :is-loading="isLoading"
    @click="onClick"
  >
    {{ label }}
    <fluent-icon :icon="icon" size="18" />
  </woot-button>
</template>

<script>
export default {
  props: {
    label: {
      type: String,
      default: '',
    },
    icon: {
      type: String,
      default: '',
    },
    isDisabled: {
      type: Boolean,
      default: false,
    },
    isLoading: {
      type: Boolean,
      default: false,
    },
  },
  methods: {
    onClick() {
      this.$emit('click');
    },
  },
};
</script>

<style lang="scss" scoped>
.submit--button {
  align-items: center;
  display: flex;
  margin: 0 0 var(--space-normal) 0;

  &::v-deep .button__content {
    align-items: center;
    display: flex;
    justify-content: center;
  }
}
</style>
