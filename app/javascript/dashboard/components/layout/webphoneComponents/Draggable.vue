<template>
  <div
    ref="draggable"
    :class="['absolute cursor-pointer', borderClass, 'rounded-xl', 'z-40']"
    :style="{ left: x + 'px', top: y + 'px' }"
    @mousedown="startDrag"
  >
    <slot />
  </div>
</template>

<script>
export default {
  props: {
    initialX: {
      type: Number,
      default: 0,
    },
    initialY: {
      type: Number,
      default: 0,
    },
  },
  data() {
    return {
      dragging: false,
      offset: { x: 0, y: 0 },
      x: 0,
      y: 0,
      borderClass: '',
    };
  },
  mounted() {
    // Recupera a posição do localStorage
    const savedPosition = localStorage.getItem('draggablePosition');
    if (savedPosition) {
      const { x, y } = JSON.parse(savedPosition);
      this.x = x;
      this.y = y;
    } else {
      // Se não houver posição salva, usa os valores iniciais
      this.x = this.initialX;
      this.y = this.initialY;
    }
  },
  methods: {
    startDrag(event) {
      this.dragging = true;
      this.offset.x = event.clientX - this.x;
      this.offset.y = event.clientY - this.y;

      document.addEventListener('mousemove', this.onDrag);
      document.addEventListener('mouseup', this.stopDrag);
    },
    onDrag(event) {
      if (!this.dragging) return;

      const newX = event.clientX - this.offset.x;
      const newY = event.clientY - this.offset.y;
      const bodyWidth = document.body.clientWidth;
      const bodyHeight = document.body.clientHeight;
      const elementWidth = this.$refs.draggable.clientWidth;
      const elementHeight = this.$refs.draggable.clientHeight;

      const isAtLeft = newX <= 0;
      const isAtRight = newX + elementWidth >= bodyWidth;
      const isAtTop = newY <= 0;
      const isAtBottom = newY + elementHeight >= bodyHeight;

      let borderClasses = [];

      if (isAtLeft) borderClasses.push('border-l border-red-500');
      if (isAtRight) borderClasses.push('border-r border-red-500');
      if (isAtTop) borderClasses.push('border-t border-red-500');
      if (isAtBottom) borderClasses.push('border-b border-red-500');

      this.borderClass = borderClasses.join(' ');

      this.x = Math.max(0, Math.min(newX, bodyWidth - elementWidth));
      this.y = Math.max(0, Math.min(newY, bodyHeight - elementHeight));
    },
    stopDrag() {
      this.dragging = false;
      document.removeEventListener('mousemove', this.onDrag);
      document.removeEventListener('mouseup', this.stopDrag);

      // Salva a posição no localStorage
      localStorage.setItem(
        'draggablePosition',
        JSON.stringify({ x: this.x, y: this.y })
      );
    },
  },
};
</script>

<style>
body {
  position: relative;
  height: 100vh;
  margin: 0;
  overflow: hidden;
}
</style>
