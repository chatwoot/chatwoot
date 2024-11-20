<!-- Attribute type "Checkbox" -->
<script setup>
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  attribute: {
    type: Object,
    required: true,
  },
  isEditingView: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update', 'delete']);

const handleChange = event => {
  emit('update', event.target.checked);
};
</script>

<template>
  <div
    class="flex items-center w-full gap-2"
    :class="{
      'justify-start': isEditingView,
      'justify-end': !isEditingView,
    }"
  >
    <input
      :checked="Boolean(attribute.value)"
      class="px-2 py-1 text-sm border rounded bg-n-solid-2 border-n-slate-5"
      type="checkbox"
      @change="handleChange"
    />

    <Button
      v-if="isEditingView"
      variant="faded"
      color="ruby"
      icon="i-lucide-trash"
      size="xs"
      class="flex-shrink-0 opacity-0 group-hover/attribute:opacity-100 hover:no-underline"
      @click="emit('delete')"
    />
  </div>
</template>
