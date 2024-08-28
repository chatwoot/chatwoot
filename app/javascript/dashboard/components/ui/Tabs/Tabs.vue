<script>
export default {
  name: 'WootTabs',
  props: {
    index: {
      type: Number,
      default: 0,
    },
    border: {
      type: Boolean,
      default: true,
    },
  },
  data() {
    return { hasScroll: false };
  },
  created() {
    window.addEventListener('resize', this.computeScrollWidth);
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.computeScrollWidth);
  },
  mounted() {
    this.computeScrollWidth();
  },
  methods: {
    computeScrollWidth() {
      const tabElement = this.$el.getElementsByClassName('tabs')[0];
      this.hasScroll = tabElement.scrollWidth > tabElement.clientWidth;
    },
    onScrollClick(direction) {
      const tabElement = this.$el.getElementsByClassName('tabs')[0];
      let scrollPosition = tabElement.scrollLeft;
      if (direction === 'left') {
        scrollPosition -= 100;
      } else {
        scrollPosition += 100;
      }
      tabElement.scrollTo({
        top: 0,
        left: scrollPosition,
        behavior: 'smooth',
      });
    },
  },
};
</script>

<template>
  <div
    :class="{ 'tabs--container--with-border': border }"
    class="tabs--container"
  >
    <button
      v-if="hasScroll"
      class="tabs--scroll-button button clear secondary button--only-icon"
      @click="onScrollClick('left')"
    >
      <fluent-icon icon="chevron-left" :size="16" />
    </button>
    <ul :class="{ 'tabs--with-scroll': hasScroll }" class="tabs">
      <slot />
    </ul>
    <button
      v-if="hasScroll"
      class="tabs--scroll-button button clear secondary button--only-icon"
      @click="onScrollClick('right')"
    >
      <fluent-icon icon="chevron-right" :size="16" />
    </button>
  </div>
</template>
