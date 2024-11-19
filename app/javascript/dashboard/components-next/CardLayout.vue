<script setup>
defineProps({
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
    class="relative flex flex-col w-full shadow outline-1 outline outline-n-container group/cardLayout rounded-2xl bg-n-solid-2"
  >
    <div
      class="flex w-full gap-3 px-6 py-5"
      :class="
        layout === 'col' ? 'flex-col' : 'flex-row justify-between items-center'
      "
      @click="handleClick"
    >
      <slot name="header" />
      <slot name="footer" />
    </div>

    <slot name="expanded" />
  </div>
</template>
