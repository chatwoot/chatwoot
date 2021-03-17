<template>
  <button
    class="button"
    :class="[
      variant,
      size,
      colorScheme,
      classNames,
      isDisabled ? 'disabled' : '',
    ]"
    :disabled="isDisabled || isLoading"
    @click="handleClick"
  >
    <spinner v-if="isLoading" size="small" />
    <i v-if="icon" :class="icon"></i>
    <span v-if="$slots.default"><slot></slot></span>
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
  },
  methods: {
    handleClick(evt) {
      this.$emit('click', evt);
    },
  },
};
</script>
