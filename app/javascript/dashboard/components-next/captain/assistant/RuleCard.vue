<script setup>
import { computed } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';
import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  content: {
    type: String,
    required: true,
  },
  selectable: {
    type: Boolean,
    default: false,
  },
  isSelected: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['select', 'hover', 'edit', 'delete']);

const modelValue = computed({
  get: () => props.isSelected,
  set: () => emit('select', props.id),
});
</script>

<template>
  <CardLayout
    selectable
    class="relative [&>div]:!py-5 [&>div]:ltr:!pr-4 [&>div]:rtl:!pl-4"
    layout="row"
    @mouseenter="emit('hover', true)"
    @mouseleave="emit('hover', false)"
  >
    <div v-show="selectable" class="absolute top-6 ltr:left-3 rtl:right-3">
      <Checkbox v-model="modelValue" />
    </div>
    <span class="flex items-center gap-2 text-sm text-n-slate-12">
      {{ content }}
    </span>
    <div class="flex items-center gap-2">
      <Button icon="i-lucide-pen" slate xs ghost @click="emit('edit', id)" />
      <span class="w-px h-4 bg-n-weak" />
      <Button
        icon="i-lucide-trash"
        slate
        xs
        ghost
        @click="emit('delete', id)"
      />
    </div>
  </CardLayout>
</template>
