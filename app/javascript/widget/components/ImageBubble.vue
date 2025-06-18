<script>
export default {
  props: {
    url: { type: String, default: '' },
    thumb: { type: String, default: '' },
    readableTime: { type: String, default: '' },
  },
  emits: ['error'],
  methods: {
    onImgError() {
      this.$emit('error');
    },
  },
};
</script>

<template>
  <a
    :href="url"
    target="_blank"
    rel="noreferrer noopener nofollow"
    class="image"
  >
    <div class="wrap">
      <img :src="thumb" alt="Picture message" @error="onImgError" />
      <span class="time">{{ readableTime }}</span>
    </div>
  </a>
</template>

<style lang="scss" scoped>
.image {
  display: block;

  .wrap {
    position: relative;
    display: flex;
    max-width: 100%;

    &::before {
      background-image: linear-gradient(-180deg, transparent 3%, #1f2d3d 130%);
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
    max-width: 250px;
  }

  .time {
    @apply text-xs bottom-1 text-white ltr:right-3 rtl:left-3 whitespace-nowrap absolute;
  }
}
</style>
