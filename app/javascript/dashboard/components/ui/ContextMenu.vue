<script setup>
import { ref, computed, onMounted, nextTick, defineEmits } from 'vue';

const { x, y } = defineProps({
  x: { type: Number, default: 0 },
  y: { type: Number, default: 0 },
});
const emit = defineEmits(['close']);

const left = ref(x);
const top = ref(y);

const style = computed(() => ({
  top: top.value + 'px',
  left: left.value + 'px',
}));

const target = ref();
onMounted(() => {
  nextTick(() => {
    target.value.focus();
  });
});
</script>

<template>
  <Teleport to="body">
    <div
      ref="target"
      class="fixed outline-none z-[9999] cursor-pointer"
      :style="style"
      tabindex="0"
      @blur="emit('close')"
    >
      <slot />
    </div>
  </Teleport>
</template>
