<script>
/**
 * Thumbnail Component
 * Src - source for round image
 * Size - Size of the thumbnail
 * Badge - Chat source indication { fb / telegram }
 * Username - Username for avatar
 */
import Avatar from './Avatar.vue';
import { removeEmoji } from 'shared/helpers/emoji';

export default {
  components: {
    Avatar,
  },
  props: {
    src: {
      type: String,
      default: '',
    },
    size: {
      type: String,
      default: '40px',
    },
    badge: {
      type: String,
      default: '',
    },
    username: {
      type: String,
      default: '',
    },
    status: {
      type: String,
      default: '',
    },
    hasBorder: {
      type: Boolean,
      default: false,
    },
    shouldShowStatusAlways: {
      type: Boolean,
      default: false,
    },
    title: {
      type: String,
      default: '',
    },
    variant: {
      type: String,
      default: 'circle',
    },
  },
  data() {
    return {
      hasImageLoaded: false,
      imgError: false,
    };
  },
  computed: {
    userNameWithoutEmoji() {
      return removeEmoji(this.username);
    },
    showStatusIndicator() {
      if (this.shouldShowStatusAlways) return true;
      return this.status === 'online' || this.status === 'busy';
    },
    avatarSize() {
      return Number(this.size.replace(/\D+/g, ''));
    },
    badgeSrc() {
      return {
        instagram_direct_message: 'instagram-dm',
        facebook: 'messenger',
        'twitter-tweet': 'twitter-tweet',
        'twitter-dm': 'twitter-dm',
        whatsapp: 'whatsapp',
        sms: 'sms',
        'Channel::Line': 'line',
        'Channel::Telegram': 'telegram',
        'Channel::WebWidget': '',
      }[this.badge];
    },
    badgeStyle() {
      const size = Math.floor(this.avatarSize / 3);
      const badgeSize = `${size + 2}px`;
      const borderRadius = `${size / 2}px`;
      return { width: badgeSize, height: badgeSize, borderRadius };
    },
    statusStyle() {
      const statusSize = `${this.avatarSize / 4}px`;
      return { width: statusSize, height: statusSize };
    },
    thumbnailClass() {
      const className = this.hasBorder
        ? 'border border-solid border-white dark:border-n-weak'
        : '';
      const variant =
        this.variant === 'circle' ? 'thumbnail-rounded' : 'thumbnail-square';
      return `user-thumbnail ${className} ${variant}`;
    },
    thumbnailBoxClass() {
      const boxClass = this.variant === 'circle' ? 'is-rounded' : '';
      return `user-thumbnail-box ${boxClass}`;
    },
    shouldShowImage() {
      if (!this.src) {
        return false;
      }
      if (this.hasImageLoaded) {
        return !this.imgError;
      }
      return false;
    },
  },
  watch: {
    src(value, oldValue) {
      if (value !== oldValue && this.imgError) {
        this.imgError = false;
      }
    },
  },
  methods: {
    onImgError() {
      this.imgError = true;
    },
    onImgLoad() {
      this.hasImageLoaded = true;
    },
  },
};
</script>

<template>
  <div
    :class="thumbnailBoxClass"
    :style="{ height: size, width: size }"
    :title="title"
  >
    <!-- Using v-show instead of v-if to avoid flickering as v-if removes dom elements.  -->
    <slot>
      <img
        v-show="shouldShowImage"
        :src="src"
        draggable="false"
        :class="thumbnailClass"
        @load="onImgLoad"
        @error="onImgError"
      />
      <Avatar
        v-show="!shouldShowImage"
        :username="userNameWithoutEmoji"
        :class="thumbnailClass"
        :size="avatarSize"
      />
    </slot>
    <img
      v-if="badgeSrc"
      class="source-badge z-20"
      :style="badgeStyle"
      :src="`/integrations/channels/badges/${badgeSrc}.png`"
      alt="Badge"
    />
    <div
      v-if="showStatusIndicator"
      class="z-20"
      :class="`source-badge user-online-status user-online-status--${status}`"
      :style="statusStyle"
    />
  </div>
</template>

<style lang="scss" scoped>
.user-thumbnail-box {
  flex: 0 0 auto;
  max-width: 100%;
  position: relative;

  &.is-rounded {
    border-radius: 50%;
  }

  .user-thumbnail {
    border-radius: 50%;
    &.thumbnail-square {
      border-radius: 0.5625rem;
    }
    height: 100%;
    width: 100%;
    box-sizing: border-box;
    object-fit: cover;
    vertical-align: initial;
  }

  .source-badge {
    border-radius: 0.1875rem;
    bottom: -0.125rem;
    box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
    position: absolute;
    right: 0;
    @apply bg-n-background p-0.5 size-3;
  }

  .user-online-status {
    @apply bottom-0.5 rounded-full;

    &:after {
      content: ' ';
    }
  }

  .user-online-status--online {
    @apply bg-n-teal-10;
  }

  .user-online-status--busy {
    @apply bg-n-amber-10;
  }

  .user-online-status--offline {
    @apply bg-n-slate-10;
  }
}
</style>
