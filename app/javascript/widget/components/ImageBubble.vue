<template>
  <a :href="url" target="_blank" class="image">
    <div class="wrap">
      <img :src="thumb" alt="Picture message" />
      <span class="time">{{ readableTime }}</span>
    </div>
  </a>
</template>

<script>
export default {
  props: ['url', 'thumb', 'readableTime'],
};
</script>
<style lang="scss" scoped>
@import '~widget/assets/scss/variables.scss';

.image {
  display: block;

  .wrap {
    position: relative;
    display: flex;
    max-width: 100%;

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
}
</style>
