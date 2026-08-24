<script setup>
import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  name: {
    type: String,
    default: '',
  },
  body: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['edit', 'delete']);
</script>

<template>
  <CardLayout layout="row">
    <div class="flex flex-col items-start flex-1 min-w-0 gap-1">
      <span class="text-base font-medium text-n-slate-12 line-clamp-1">
        {{ name }}
      </span>
      <p class="mb-0 text-sm text-n-slate-11 line-clamp-2">
        {{ body }}
      </p>
    </div>
    <div class="flex items-center justify-end w-20 gap-2">
      <Button
        variant="faded"
        size="sm"
        color="slate"
        icon="i-lucide-sliders-vertical"
        @click="emit('edit')"
      />
      <Button
        variant="faded"
        color="ruby"
        size="sm"
        icon="i-lucide-trash"
        @click="emit('delete')"
      />
    </div>
  </CardLayout>
</template>
