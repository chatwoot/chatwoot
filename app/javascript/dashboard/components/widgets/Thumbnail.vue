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
      v-if="badge === 'Channel::FacebookPage'"
      id="badge"
      class="source-badge"
      :style="badgeStyle"
      src="~dashboard/assets/images/fb-badge.png"
    />
    <div
      v-else-if="status === 'online'"
      class="source-badge user--online"
      :style="statusStyle"
    ></div>
    <img
      v-if="badge === 'Channel::TwitterProfile'"
      id="badge"
      class="source-badge"
      :style="badgeStyle"
      src="~dashboard/assets/images/twitter-badge.png"
    />

    <img
      v-if="badge === 'Channel::TwilioSms'"
      id="badge"
      class="source-badge"
      :style="badgeStyle"
      src="~dashboard/assets/images/channels/whatsapp.png"
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
    avatarSize() {
      return Number(this.size.replace(/\D+/g, ''));
    },
    badgeStyle() {
      const badgeSize = `${this.avatarSize / 3}px`;
      return { width: badgeSize, height: badgeSize };
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

    &.border {
      border: 1px solid white;
    }
  }

  .source-badge {
    bottom: -$space-micro;
    height: $space-slab;
    position: absolute;
    right: $zero;
    width: $space-slab;
  }

  .user--online {
    background: $success-color;
    border-radius: 50%;
    bottom: $space-micro;

    &:after {
      content: ' ';
    }
  }
}
</style>
