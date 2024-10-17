<script setup>
const emit = defineEmits(['click']);
const handleClick = () => {
  emit('click');
};
</script>

<template>
  <div
    class="relative flex flex-col w-full gap-3 px-6 py-5 shadow-sm group/cardLayout rounded-2xl bg-n-solid-1"
    @click="handleClick"
  >
    <slot name="header" />
    <slot name="footer" />
  </div>
</template>
