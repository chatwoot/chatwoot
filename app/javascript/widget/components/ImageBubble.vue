<template>
  <a :href="url" target="_blank" class="image message-text__wrap">
    <img :src="url" alt="Picture message" />
    <span class="time">{{ readableTime }}</span>
  </a>
</template>

<script>
export default {
  props: ['url', 'readableTime'],
};
</script>
<style lang="scss" scoped>
@import '~widget/assets/scss/variables.scss';

.image {
  max-width: 100%;
  position: relative;
  display: block;

  img {
    width: 100%;
  }

  .time {
    font-size: $font-size-small;
    bottom: $space-smaller;
    color: $color-white;
    position: absolute;
    right: $space-small;
    white-space: nowrap;
  }

  &::before {
    $color-black: #000;
    background-image: linear-gradient(
      -180deg,
      transparent 3%,
      $color-black 70%
    );
    bottom: 0;
    content: '';
    height: 20%;
    left: 0;
    opacity: 0.8;
    position: absolute;
    width: 100%;
  }
}
</style>
