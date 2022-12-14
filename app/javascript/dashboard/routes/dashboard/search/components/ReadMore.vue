<template>
  <div class="read-more">
    <div ref="content" :class="{ content: applyReadMore }">
      <slot />
      <woot-button
        size="tiny"
        variant="smooth"
        color-scheme="primary"
        class="read-more-button"
      >
        Read more
      </woot-button>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    applyReadMore: {
      type: Boolean,
      default: false,
    },
  },
};
</script>

<style lang="scss" scoped>
.content {
  max-height: 100px;
  overflow: hidden;
  position: relative;
}

.content::after {
  content: '';
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 50px;
  background: linear-gradient(to bottom, rgba(255, 255, 255, 0), #fff 100%);
  z-index: 4;
}

.read-more-button {
  max-width: max-content;
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  margin: 0 auto;
  z-index: 5;
}
</style>
