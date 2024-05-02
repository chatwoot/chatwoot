<template>
  <div ref="observedElement" class="h-6 w-full" />
</template>

<script>
export default {
  props: {
    options: {
      type: Object,
      default: () => ({ root: document, rootMargin: '100px 0 100px 0)' }),
    },
  },
  mounted() {
    this.intersectionObserver = null;
    this.registerInfiniteLoader();
  },
  beforeDestroy() {
    this.unobserveInfiniteLoadObserver();
  },
  methods: {
    registerInfiniteLoader() {
      this.intersectionObserver = new IntersectionObserver(entries => {
        if (entries && entries[0].isIntersecting) {
          this.$emit('observed');
        }
      }, this.options);
      this.intersectionObserver.observe(this.$refs.observedElement);
    },
    unobserveInfiniteLoadObserver() {
      this.intersectionObserver.unobserve(this.$refs.observedElement);
    },
  },
};
</script>
