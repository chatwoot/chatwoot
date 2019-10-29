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
    >
    </Avatar>
    <img
      v-if="badge === 'Facebook'"
      id="badge"
      class="source-badge"
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
  methods: {
    onImgError() {
      this.imgError = true;
    },
  },
};
</script>
