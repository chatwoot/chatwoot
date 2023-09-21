<template>
  <i v-if="showEmoji" :class="className">{{ iconContent }}</i>
  <fluent-icon
    v-else-if="showIcon"
    :size="iconSize"
    :icon="icon"
    :class="className"
  />
</template>

<script>
import { hasEmojiSupport } from 'shared/helpers/emoji';
import { mapGetters } from 'vuex';

export default {
  props: {
    icon: { type: String, default: '' },
    iconSize: { type: [Number, String], default: 20 },
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
