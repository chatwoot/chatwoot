<template>
  <button
    class="button"
    :type="type"
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
      :icon-size="iconSize"
    />
    <span v-if="$slots.default" class="button__content">
      <slot />
    </span>
  </button>
</template>
<script>
import Spinner from 'shared/components/Spinner';
import EmojiOrIcon from 'shared/components/EmojiOrIcon';

export default {
  name: 'WootButton',
  components: { EmojiOrIcon, Spinner },
  props: {
    type: {
      type: String,
      default: 'submit',
    },
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
    hasOnlyIcon() {
      const hasEmojiOrIcon = this.emoji || this.icon;
      return !this.$slots.default && hasEmojiOrIcon;
    },
    hasOnlyIconClasses() {
      return this.hasOnlyIcon ? 'button--only-icon' : '';
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
    iconSize() {
      switch (this.size) {
        case 'tiny':
          return 12;
        case 'small':
          return 14;
        case 'medium':
          return 16;
        case 'large':
          return 18;

        default:
          return 16;
      }
    },
  },
  methods: {
    handleClick(evt) {
      this.$emit('click', evt);
    },
  },
};
</script>
