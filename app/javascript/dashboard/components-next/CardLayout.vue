<script setup>
const emit = defineEmits(['click']);
const handleClick = () => {
  emit('click');
};
</script>

<template>
  <div
    class="relative flex flex-col w-full gap-3 px-6 py-5 group/cardLayout hover:cursor-pointer rounded-2xl bg-n-solid-1 shadow-sm"
    @click="handleClick"
  >
    <slot name="header" />
    <slot name="footer" />
  </div>
</template>
