<script setup>
import { computed, onMounted, nextTick, useTemplateRef } from 'vue';
import { useWindowSize, useElementBounding } from '@vueuse/core';
import { calculatePosition } from 'dashboard/helper/position.js';

const props = defineProps({
  x: { type: Number, default: 0 },
  y: { type: Number, default: 0 },
});

const emit = defineEmits(['close']);

const menuRef = useTemplateRef('menuRef');

const { width: windowWidth, height: windowHeight } = useWindowSize();
const { width: menuWidth, height: menuHeight } = useElementBounding(menuRef);

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
  <Teleport to="body">
    <div
      ref="menuRef"
      class="fixed outline-none z-[9999] cursor-pointer"
      :style="position"
      tabindex="0"
      @blur="emit('close')"
    >
      <slot />
    </div>
  </Teleport>
</template>
