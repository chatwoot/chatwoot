<template>
  <div class="user-thumbnail-box" v-bind:style="{ height: size, width: size }">
    <img v-bind:src="src" class="user-thumbnail">
    <img class="source-badge" src="~assets/images/fb-badge.png" v-if="badge === 'Facebook'">
  </div>
</template>
<script>
/**
 * Thumbnail Component
 * Src - source for round image
 * Size - Size of the thumbnail
 * Badge - Chat source indication { fb / telegram }
 */
export default {
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
  },
};
</script>