<template>
  <button
    class="button"
    :class="[
      variantClasses,
      size,
      colorScheme,
      classNames,
      isDisabled ? 'disabled' : '',
      isExpanded ? 'expanded' : '',
    ]"
    :disabled="isDisabled || isLoading"
    @click="handleClick"
  >
    <spinner v-if="isLoading" size="small" />
    <i v-else-if="icon" class="icon" :class="icon"></i>
    <span v-if="$slots.default" class="button__content"><slot></slot></span>
  </button>
</template>
<script>
import Spinner from 'shared/components/Spinner.vue';

export default {
  name: 'WootButton',
  components: { Spinner },
  props: {
    variant: {
      type: String,
      default: '',
    },
    size: {
      type: String,
      default: '',
    },
    icon: {
      type: String,
      default: '',
    },
    colorScheme: {
      type: String,
      default: 'primary',
    },
    classNames: {
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
    isExpanded: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    variantClasses() {
      if (this.variant.includes('link')) {
        return `clear ${this.variant}`;
      }
      return this.variant;
    },
  },
  methods: {
    handleClick(evt) {
      this.$emit('click', evt);
    },
  },
};
</script>
<style lang="scss" scoped>
.spinner {
  padding: 0 var(--space-small);
}
.icon + .button__content {
  padding-left: var(--space-small);
}
</style>
