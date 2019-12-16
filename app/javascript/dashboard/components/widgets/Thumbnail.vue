<template>
  <div class="user-thumbnail-box" :style="{ height: size, width: size }">
    <img
      v-if="!imgError && Boolean(src)"
      id="image"
      :src="src"
      class="user-thumbnail"
      @error="onImgError()"
    />
    <Avatar
      v-else
      :username="username"
      class="user-thumbnail"
      background-color="#1f93ff"
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
@import '~dashboard/assets/scss/mixins';

.user-thumbnail-box {
  @include flex-shrink;
  position: relative;

  .user-thumbnail {
    border-radius: 50%;
    height: 100%;
    width: 100%;
  }

  .source-badge {
    bottom: -$space-micro / 2;
    height: $space-slab;
    position: absolute;
    right: $zero;
    width: $space-slab;
  }
}
</style>
