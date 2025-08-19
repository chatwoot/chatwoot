<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  id: { type: Number, required: true },
  title: { type: String, required: true },
  description: { type: String, required: true },
  category: { type: String, required: true },
  createdAt: { type: String, required: true },
  tags: { type: Array, default: () => [] },
});

const emit = defineEmits(['view', 'edit']);

const { t } = useI18n();

const formattedDate = computed(() => {
  return new Date(props.createdAt).toLocaleDateString();
});

const categoryIcon = computed(() => {
  const iconMap = {
    Guidelines: 'i-lucide-book-open',
    Documentation: 'i-lucide-file-text',
    Troubleshooting: 'i-lucide-wrench',
    Sales: 'i-lucide-trending-up',
    Internal: 'i-lucide-users',
    Procedures: 'i-lucide-list-checks',
  };
  return iconMap[props.category] || 'i-lucide-file';
});

const handleView = () => emit('view', props.id);
const handleEdit = () => emit('edit', props.id);
</script>

<template>
  <CardLayout :key="id" layout="column">
    <div class="flex flex-col gap-4 w-full">
      <!-- Header -->
      <div class="flex items-center gap-3">
        <div
          class="flex items-center justify-center w-10 h-10 rounded-lg bg-n-solid-3"
        >
          <span :class="categoryIcon" class="text-lg text-n-slate-11" />
        </div>
        <div class="flex-1 min-w-0">
          <h3 class="text-lg font-semibold text-n-base truncate">
            {{ title }}
          </h3>
          <div class="flex items-center gap-2 mt-1">
            <span
              class="inline-flex items-center px-2 py-1 text-xs font-medium rounded-md bg-n-alpha-2 text-n-slate-12"
            >
              {{ category }}
            </span>
            <span class="text-sm text-n-slate-11">
              {{ t('LIBRARY.CARD.CREATED_ON') }} {{ formattedDate }}
            </span>
          </div>
        </div>
      </div>

      <!-- Description -->
      <div class="flex flex-col gap-3">
        <p class="text-n-slate-12 leading-relaxed">
          {{ description }}
        </p>

        <!-- Tags -->
        <div v-if="tags.length > 0" class="flex flex-wrap gap-2">
          <span
            v-for="tag in tags"
            :key="tag"
            class="inline-flex items-center px-2 py-1 text-xs rounded-md bg-n-alpha-1 text-n-slate-11"
          >
            {{ tag }}
          </span>
        </div>
      </div>

      <!-- Actions -->
      <div class="flex justify-end gap-2 pt-4 border-t border-n-weak w-full">
        <Button
          variant="outline"
          size="sm"
          icon="i-lucide-eye"
          @click="handleView"
        >
          {{ t('LIBRARY.CARD.VIEW') }}
        </Button>
        <Button
          variant="outline"
          size="sm"
          icon="i-lucide-edit"
          @click="handleEdit"
        >
          {{ t('LIBRARY.CARD.EDIT') }}
        </Button>
      </div>
    </div>
  </CardLayout>
</template>
