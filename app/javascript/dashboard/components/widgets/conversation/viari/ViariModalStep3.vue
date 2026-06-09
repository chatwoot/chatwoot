<script setup>
const props = defineProps({
  formData: { type: Object, required: true },
  isCreating: { type: Boolean, default: false },
  createError: { type: String, default: '' },
});
const emit = defineEmits(['confirm', 'back']);
</script>

<template>
  <div
    class="p-5 min-h-[200px]"
    :data-creating="props.isCreating"
    :data-error="props.createError"
    :data-stub="props.formData ? '1' : '0'"
    @keydown.enter="emit('confirm')"
    @keydown.escape="emit('back')"
  />
</template>
