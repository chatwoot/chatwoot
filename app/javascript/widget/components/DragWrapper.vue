<template>
  <div
    :style="{ transform: `translateX(${dragDistance}px)` }"
    class="will-change-transform"
    @touchstart="handleTouchStart"
    @touchmove="handleTouchMove"
    @touchend="resetPosition"
  >
    <slot />
  </div>
</template>

<script>
export default {
  name: 'DragWrapper',
  props: {
    direction: {
      type: String,
      required: true,
      validator: value => ['left', 'right'].includes(value),
    },
    disabled: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      startX: null,
      dragDistance: 0,
      threshold: 50, // Threshold value in pixels
    };
  },
  methods: {
    handleTouchStart(event) {
      if (this.disabled) return;
      this.startX = event.touches[0].clientX;
    },
    handleTouchMove(event) {
      if (this.disabled) return;
      const touchX = event.touches[0].clientX;
      let deltaX = touchX - this.startX;

      if (this.direction === 'right') {
        this.dragDistance = Math.min(this.threshold, deltaX);
      } else if (this.direction === 'left') {
        this.dragDistance = Math.max(-this.threshold, deltaX);
      }
    },
    resetPosition() {
      if (
        (this.dragDistance >= this.threshold && this.direction === 'right') ||
        (this.dragDistance <= -this.threshold && this.direction === 'left')
      ) {
        this.$emit('dragged', this.direction);
      }
      this.dragDistance = 0; // Reset the position after releasing the touch
    },
  },
};
</script>
