<script setup>
import { computed, onMounted, nextTick, useTemplateRef } from 'vue';
import { useWindowSize, useElementBounding } from '@vueuse/core';

import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';

const props = defineProps({
  x: { type: Number, default: 0 },
  y: { type: Number, default: 0 },
});

const emit = defineEmits(['close']);

const menuRef = useTemplateRef('menuRef');

const { width: windowWidth, height: windowHeight } = useWindowSize();
const { width: menuWidth, height: menuHeight } = useElementBounding(menuRef);

const calculatePosition = (x, y, menuW, menuH, windowW, windowH) => {
  // Initial position
  let left = x;
  let top = y;

  // Boundary checks
  const isOverflowingRight = left + menuW > windowW;
  const isOverflowingBottom = top + menuH > windowH;

  // Adjust position if overflowing
  if (isOverflowingRight) left = windowW - menuW;
  if (isOverflowingBottom) top = windowH - menuH;

  return {
    left: Math.max(0, left),
    top: Math.max(0, top),
  };
};

const position = computed(() => {
  if (!menuRef.value) return { top: `${props.y}px`, left: `${props.x}px` };

  const { left, top } = calculatePosition(
    props.x,
    props.y,
    menuWidth.value,
    menuHeight.value,
    windowWidth.value,
    windowHeight.value
  );

  return {
    top: `${top}px`,
    left: `${left}px`,
  };
});

onMounted(() => {
  nextTick(() => menuRef.value?.focus());
});
</script>

<template>
  <TeleportWithDirection to="body">
    <div
      ref="menuRef"
      class="fixed outline-none z-[9999] cursor-pointer"
      :style="position"
      tabindex="0"
      @blur="emit('close')"
    >
      <slot />
    </div>
  </TeleportWithDirection>
</template>
