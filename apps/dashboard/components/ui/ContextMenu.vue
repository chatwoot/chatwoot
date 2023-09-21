<template>
  <div
    class="fixed outline-none z-[9999] cursor-pointer"
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
