<template>
  <button
    class="button"
    :class="buttonClasses"
    :disabled="isDisabled || isLoading"
    @click="handleClick"
  >
    <spinner v-if="isLoading" size="small" />
    <emoji-or-icon
      v-else-if="icon || emoji"
      class="icon"
      :emoji="emoji"
      :icon="icon"
    />
    <span v-if="$slots.default" class="button__content"><slot></slot></span>
  </button>
</template>
<script>
import Spinner from 'shared/components/Spinner';
import EmojiOrIcon from 'shared/components/EmojiOrIcon';

export default {
  name: 'WootButton',
  components: { EmojiOrIcon, Spinner },
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
    emoji: {
      type: String,
      default: '',
    },
    colorScheme: {
      type: String,
      default: 'primary',
    },
    classNames: {
      type: [String, Object],
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
    hasOnlyIconClasses() {
      const hasEmojiOrIcon = this.emoji || this.icon;
      if (!this.$slots.default && hasEmojiOrIcon) return 'button--only-icon';
      return '';
    },
    buttonClasses() {
      return [
        this.variantClasses,
        this.hasOnlyIconClasses,
        this.size,
        this.colorScheme,
        this.classNames,
        this.isDisabled ? 'disabled' : '',
        this.isExpanded ? 'expanded' : '',
      ];
    },
  },
  methods: {
    handleClick(evt) {
      this.$emit('click', evt);
    },
  },
};
</script>
