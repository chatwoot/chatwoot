<script setup>
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import AttributeBadge from 'dashboard/components-next/CustomAttributes/AttributeBadge.vue';
import { computed } from 'vue';

const props = defineProps({
  attribute: {
    type: Object,
    required: true,
  },
  badges: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['edit', 'delete']);

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
</script>

<template>
  <div
    class="flex flex-col gap-2 p-4 bg-n-solid-1 rounded-2xl outline outline-1 outline-n-container"
  >
    <div class="flex flex-wrap gap-2 justify-between items-center">
      <div class="flex flex-wrap gap-2 items-center min-w-0">
        <h4 class="text-sm font-medium truncate text-n-slate-12">
          {{ attribute.label }}
        </h4>
        <div class="w-px h-3 bg-n-strong" />
        <div class="flex gap-2 items-center text-sm text-n-slate-11">
          <div class="flex items-center gap-1.5 text-n-slate-11">
            <Icon :icon="attributeIcon" class="size-4" />
            <span class="text-sm">{{ attribute.type }}</span>
          </div>
          <div class="w-px h-3 bg-n-weak" />
          <div class="flex items-center gap-1.5 text-n-slate-11">
            <Icon icon="i-lucide-key-round" class="size-4" />
            <span class="line-clamp-1 text-sm">{{ attribute.value }}</span>
          </div>
        </div>
      </div>
      <div class="flex gap-2 items-center">
        <AttributeBadge
          v-for="badge in badges"
          :key="badge.type"
          :type="badge.type"
        />
        <div
          v-if="badges.length > 0"
          class="w-px h-3 bg-n-strong ltr:ml-1.5 rtl:mr-1.5"
        />
        <Button
          icon="i-lucide-pencil-line"
          size="sm"
          color="slate"
          ghost
          @click="emit('edit', attribute)"
        />
        <div class="w-px h-3 bg-n-strong" />
        <Button
          icon="i-lucide-trash"
          size="sm"
          color="slate"
          ghost
          @click="emit('delete', attribute)"
        />
      </div>
    </div>
    <p class="mb-0 text-sm text-n-slate-11">
      {{ attribute.attribute_description || attribute.description || '' }}
    </p>
  </div>
</template>
