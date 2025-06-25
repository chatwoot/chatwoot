<template>
  <div
    class="context-menu-container"
    :style="style"
    tabindex="0"
    @blur="$emit('close')"
  >
    <slot />
  </div>
</template>
<script>
export default {
  props: {
    x: {
      type: Number,
      default: 0,
    },
    y: {
      type: Number,
      default: 0,
    },
  },
  data() {
    return {
      left: this.x,
      top: this.y,
      show: false,
    };
  },
  computed: {
    style() {
      return {
        top: this.top + 'px',
        left: this.left + 'px',
      };
    },
  },
  mounted() {
    this.$nextTick(() => this.$el.focus());
  },
};
</script>
<style>
.context-menu-container {
  position: fixed;
  z-index: var(--z-index-very-high);
  outline: none;
  cursor: pointer;
}
</style>
