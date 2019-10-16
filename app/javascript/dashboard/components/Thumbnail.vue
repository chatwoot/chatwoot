<template>
  <div class="profile-card">
    <div class="profile-image" v-bind:style="{ height: size, width: size }">
      <img v-bind:src="src">
    </div>
    <img class="source-badge" src="../assets/images/fb-badge.png" v-if="badge === 'fb'">
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
  props: ['src', 'size', 'badge'],
};
</script>