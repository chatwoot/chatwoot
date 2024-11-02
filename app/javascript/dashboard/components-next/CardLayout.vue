<script setup>
const props = defineProps({
  layout: {
    type: String,
    default: 'col',
  },
});
const emit = defineEmits(['click']);
const handleClick = () => {
  emit('click');
};
</script>

<template>
  <div
    class="relative flex w-full gap-3 px-6 py-5 shadow outline-1 outline outline-n-container group/cardLayout rounded-2xl bg-n-solid-2"
    :class="props.layout === 'col' ? 'flex-col' : 'flex-row'"
    @click="handleClick"
  >
    <slot name="header" />
    <slot name="footer" />
  </div>
</template>
