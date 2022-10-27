<template>
  <div class="image message-text__wrap">
    <h5 class="text-block-title">
      {{ name }}
    </h5>
    <a
      :href="'https://maps.google.com/?q=' + latitude + ',' + longitude"
      target="_blank"
      class="text-content c-white"
      rel="noopener noreferrer nofollow"
    >
      <img src="~dashboard/assets/images/map_image.jpg" alt="Location" />
    </a>
  </div>
</template>

<script>
export default {
  props: {
    latitude: {
      type: Number,
      default: undefined,
    },
    longitude: {
      type: Number,
      default: undefined,
    },
    name: {
      type: String,
      default: '',
    },
  },
};
</script>

<style scoped></style>
