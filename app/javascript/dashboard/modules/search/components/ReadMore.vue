<template>
  <div class="read-more">
    <div
      ref="content"
      :class="{
        'shrink-container after:shrink-gradient-light dark:after:shrink-gradient-dark':
          shrink,
      }"
    >
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

<style scoped>
@tailwind components;
@layer components {
  .shrink-gradient-light {
    background: linear-gradient(
      to bottom,
      rgba(255, 255, 255, 0),
      rgba(255, 255, 255, 1) 100%
    );
  }

  .shrink-gradient-dark {
    background: linear-gradient(
      to bottom,
      rgba(0, 0, 0, 0),
      rgb(21, 23, 24) 100%
    );
  }
}
.shrink-container {
  @apply max-h-[100px] overflow-hidden relative;
}
.shrink-container::after {
  @apply content-[''] absolute bottom-0 left-0 right-0 h-[50px] z-10;
}
.read-more-button {
  @apply max-w-max absolute bottom-2 left-0 right-0 mx-auto mt-0 z-20 shadow-sm;
}
</style>
