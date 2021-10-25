<template>
  <div class="user-thumbnail-box" :style="{ height: size, width: size }">
    <img
      v-if="!imgError && Boolean(src)"
      id="image"
      :src="src"
      :class="thumbnailClass"
      @error="onImgError()"
    />
    <Avatar
      v-else
      :username="username"
      :class="thumbnailClass"
      color="white"
      :size="avatarSize"
    />
    <img
      v-if="badge === 'instagram_direct_message'"
      id="badge"
      class="source-badge"
      :style="badgeStyle"
      src="/integrations/channels/badges/instagram-dm.png"
    />
    <img
      v-else-if="badge === 'facebook'"
      id="badge"
      class="source-badge"
      :style="badgeStyle"
      src="/integrations/channels/badges/messenger.png"
    />
    <img
      v-else-if="badge === 'twitter-tweet'"
      id="badge"
      class="source-badge"
      :style="badgeStyle"
      src="/integrations/channels/badges/twitter-tweet.png"
    />
    <img
      v-else-if="badge === 'twitter-dm'"
      id="badge"
      class="source-badge"
      :style="badgeStyle"
      src="/integrations/channels/badges/twitter-dm.png"
    />
    <img
      v-else-if="badge === 'whatsapp'"
      id="badge"
      class="source-badge"
      :style="badgeStyle"
      src="/integrations/channels/badges/whatsapp.png"
    />
    <img
      v-else-if="badge === 'sms'"
      id="badge"
      class="source-badge"
      :style="badgeStyle"
      src="/integrations/channels/badges/sms.png"
    />
    <img
      v-else-if="badge === 'Channel::Line'"
      id="badge"
      class="source-badge"
      :style="badgeStyle"
      src="/integrations/channels/badges/line.png"
    />
    <img
      v-else-if="badge === 'Channel::Telegram'"
      id="badge"
      class="source-badge"
      :style="badgeStyle"
      src="/integrations/channels/badges/telegram.png"
    />
    <div
      v-if="showStatusIndicator"
      :class="`source-badge user-online-status user-online-status--${status}`"
      :style="statusStyle"
    />
  </div>
</template>
<script>
/**
 * Thumbnail Component
 * Src - source for round image
 * Size - Size of the thumbnail
 * Badge - Chat source indication { fb / telegram }
 * Username - User name for avatar
 */
import Avatar from './Avatar';

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
      default: 'fb',
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
  },
  data() {
    return {
      imgError: false,
    };
  },
  computed: {
    showStatusIndicator() {
      return this.status === 'online' || this.status === 'busy';
    },
    avatarSize() {
      return Number(this.size.replace(/\D+/g, ''));
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
      const classname = this.hasBorder ? 'border' : '';
      return `user-thumbnail ${classname}`;
    },
  },
  watch: {
    src: {
      handler(value, oldValue) {
        if (value !== oldValue && this.imgError) {
          this.imgError = false;
        }
      },
    },
  },
  methods: {
    onImgError() {
      this.imgError = true;
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/variables';
@import '~dashboard/assets/scss/foundation-settings';
@import '~dashboard/assets/scss/mixins';

.user-thumbnail-box {
  @include flex-shrink;
  position: relative;

  .user-thumbnail {
    border-radius: 50%;
    height: 100%;
    width: 100%;
    box-sizing: border-box;
    object-fit: cover;

    &.border {
      border: 1px solid white;
    }
  }

  .source-badge {
    background: white;
    border-radius: var(--border-radius-small);
    bottom: -$space-micro;
    box-shadow: var(--shadow-small);
    height: $space-slab;
    padding: var(--space-micro);
    position: absolute;
    right: $zero;
    width: $space-slab;
  }

  .user-online-status {
    border-radius: 50%;
    bottom: $space-micro;

    &:after {
      content: ' ';
    }
  }

  .user-online-status--online {
    background: $success-color;
  }

  .user-online-status--busy {
    background: $warning-color;
  }
}
</style>
