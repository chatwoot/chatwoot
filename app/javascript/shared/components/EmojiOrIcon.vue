<template>
  <i v-if="showWrap" :class="className">{{ iconContent }}</i>
</template>

<script>
import { hasEmojiSupport } from 'shared/helpers/emoji';

export default {
  props: {
    icon: { type: String, default: '' },
    emoji: { type: String, default: '' },
    showOnlyIcon: { type: Boolean, default: true },
  },
  computed: {
    showEmoji() {
      return this.emoji && hasEmojiSupport(this.emoji) && !this.showOnlyIcon;
    },
    showIcon() {
      return !this.showEmoji && this.icon && this.showOnlyIcon;
    },
    showWrap() {
      return this.showEmoji || this.showIcon;
    },
    iconContent() {
      return this.showEmoji ? this.emoji : '';
    },
    className() {
      return {
        'icon--emoji': this.showEmoji,
        'icon--font': this.showIcon,
        [this.icon]: this.showIcon,
      };
    },
  },
};
</script>

<style lang="scss" scoped>
.icon--emoji {
  font-style: normal;
}
</style>
