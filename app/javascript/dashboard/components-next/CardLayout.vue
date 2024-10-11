<script setup>
const emit = defineEmits(['click']);
const handleClick = () => {
  emit('click');
};
</script>

<template>
  <div
    class="relative flex flex-col w-full gap-3 px-6 py-5 group/cardLayout rounded-2xl bg-slate-25 dark:bg-slate-800/50"
    @click="handleClick"
  >
    <slot name="header" />
    <slot name="footer" />
  </div>
</template>
