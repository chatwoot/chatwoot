<script setup>
import { computed } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  attribute: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['delete']);

const iconByType = {
  text: 'i-lucide-align-justify',
  checkbox: 'i-lucide-circle-check-big',
  list: 'i-lucide-list',
  date: 'i-lucide-calendar',
  link: 'i-lucide-link',
  number: 'i-lucide-hash',
};

const attributeIcon = computed(() => {
  const typeKey = props.attribute.type?.toLowerCase();
  return iconByType[typeKey] || 'i-lucide-align-justify';
});

const handleDelete = () => {
  emit('delete', props.attribute);
};
</script>

<template>
  <div class="flex justify-between items-center px-4 py-3 w-full">
    <div class="flex gap-3 items-center">
      <h5 class="text-sm font-medium text-n-slate-12 line-clamp-1">
        {{ attribute.label }}
      </h5>
      <div class="w-px h-2.5 bg-n-slate-5" />
      <div class="flex gap-1.5 items-center">
        <Icon :icon="attributeIcon" class="size-4 text-n-slate-11" />
        <span class="text-sm text-n-slate-11">{{ attribute.type }}</span>
      </div>
      <div class="w-px h-2.5 bg-n-slate-5" />
      <div class="flex gap-1.5 items-center">
        <Icon icon="i-lucide-key-round" class="size-4 text-n-slate-11" />
        <span class="text-sm text-n-slate-11">{{ attribute.value }}</span>
      </div>
    </div>
    <div class="flex gap-2 items-center">
      <Button icon="i-lucide-trash" sm slate ghost @click.stop="handleDelete" />
    </div>
  </div>
</template>
