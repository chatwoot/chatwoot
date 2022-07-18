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
import { mixin as clickaway } from 'vue-clickaway';

export default {
  mixins: [clickaway],
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
  z-index: var(--z-index-very-high);
  outline: none;
  background-color: var(--white);
  box-shadow: var(--shadow-context-menu);
  cursor: pointer;
  border-radius: var(--border-radius-normal);
}
</style>
