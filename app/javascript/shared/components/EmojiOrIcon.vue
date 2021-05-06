<template>
  <i v-if="showWrap" :class="className">{{ iconContent }}</i>
</template>

<script>
import { hasEmojiSupport } from 'shared/helpers/emoji';
import { mapGetters } from 'vuex';

export default {
  props: {
    icon: { type: String, default: '' },
    emoji: { type: String, default: '' },
  },
  computed: {
    ...mapGetters({ uiSettings: 'getUISettings' }),
    isIconTypeEmoji() {
      const { icon_type: iconType } = this.uiSettings || {};
      return iconType === 'emoji';
    },
    showEmoji() {
      return this.isIconTypeEmoji && this.emoji && hasEmojiSupport(this.emoji);
    },
    showIcon() {
      return !this.showEmoji && this.icon;
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
