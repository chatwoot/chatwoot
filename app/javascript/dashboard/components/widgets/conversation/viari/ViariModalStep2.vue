<script setup>
const props = defineProps({
  initialData: { type: Object, required: true },
});
const emit = defineEmits(['next', 'back']);
</script>

<template>
  <div
    class="p-5 min-h-[200px]"
    :data-stub="props.initialData ? '1' : '0'"
    @keydown.enter="emit('next')"
    @keydown.escape="emit('back')"
  />
</template>
