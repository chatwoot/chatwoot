<template>
  <div class="read-more">
    <div ref="content" :class="{ 'shrink-container': shrink }">
      <slot />
      <woot-button
        v-if="shrink"
        size="tiny"
        variant="smooth"
        color-scheme="primary"
        class="read-more-button"
        @click.prevent="$emit('expand')"
      >
        {{ $t('SEARCH.READ_MORE') }}
      </woot-button>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    shrink: {
      type: Boolean,
      default: false,
    },
  },
};
</script>

<style lang="scss" scoped>
.shrink-container {
  max-height: 100px;
  overflow: hidden;
  position: relative;
}
.shrink-container::after {
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
  bottom: var(--space-small);
  left: 0;
  right: 0;
  margin: 0 auto;
  z-index: 5;
  box-shadow: var(--box-shadow);
}
</style>
