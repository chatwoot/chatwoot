<template>
  <div
    v-show="show"
    ref="context"
    class="sub-menu"
    :style="style"
    tabindex="0"
    @blur="close"
  >
    <slot />
  </div>
</template>
<script>
export default {
  props: {
    display: Boolean,
  },
  data() {
    return {
      left: 0,
      top: 0,
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
  methods: {
    close() {
      this.show = false;
      this.left = 0;
      this.top = 0;
    },
    open(evt) {
      this.left = evt.pageX || evt.clientX;
      this.top = evt.pageY || evt.clientY;
      this.$nextTick(() => this.$el.focus());
      this.show = true;
    },
  },
};
</script>
<style>
.sub-menu {
  position: fixed;
  backdrop-filter: blur(10px);
  background-color: rgba(255, 255, 255, 0.8);
  backdrop-filter: blur(20px);
  z-index: 999;
  outline: none;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.12), 0 1px 2px rgba(0, 0, 0, 0.24);
  cursor: pointer;
  border-radius: var(--border-radius-normal);
  padding: var(--space-small);
}
</style>
