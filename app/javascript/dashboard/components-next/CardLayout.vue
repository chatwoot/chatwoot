<script setup>
const emit = defineEmits(['click']);
const handleClick = () => {
  emit('click');
};
</script>

<template>
  <div
    class="relative flex flex-col w-full gap-3 px-6 py-5 shadow outline-1 outline outline-n-container group/cardLayout rounded-2xl bg-n-solid-2"
    @click="handleClick"
  >
    <slot name="header" />
    <slot name="footer" />
  </div>
</template>
