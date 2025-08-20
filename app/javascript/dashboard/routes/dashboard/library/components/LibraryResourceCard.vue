<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  id: { type: Number, required: true },
  title: { type: String, required: true },
  description: { type: String, required: true },
  createdAt: { type: String, required: true },
  isDeleting: { type: Boolean, default: false },
});

const emit = defineEmits(['edit', 'delete']);

const { t } = useI18n();
const showDeleteConfirm = ref(false);

const formattedDate = computed(() => {
  return new Date(props.createdAt).toLocaleDateString();
});

const handleEdit = () => emit('edit', props.id);

const handleDeleteClick = () => {
  showDeleteConfirm.value = true;
};

const handleDeleteConfirm = () => {
  showDeleteConfirm.value = false;
  emit('delete', props.id);
};

const handleDeleteCancel = () => {
  showDeleteConfirm.value = false;
};
</script>

<template>
  <CardLayout :key="id" layout="column">
    <div class="flex flex-col gap-4 w-full">
      <!-- Header -->
      <div class="flex items-center gap-3">
        <div class="flex-1 min-w-0">
          <h3 class="text-lg font-semibold text-n-base truncate">
            {{ title }}
          </h3>
          <div class="flex items-center gap-2 mt-1">
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
      </div>

      <!-- Actions -->
      <div class="flex justify-end gap-3 pt-4 border-t border-n-weak w-full">
        <Button
          variant="outline"
          size="sm"
          icon="i-lucide-edit"
          @click="handleEdit"
        >
          {{ t('LIBRARY.CARD.EDIT') }}
        </Button>
        <Button
          variant="danger-outline"
          size="sm"
          icon="i-lucide-trash-2"
          :disabled="isDeleting"
          @click="handleDeleteClick"
        >
          {{ t('LIBRARY.CARD.DELETE') }}
        </Button>
      </div>

      <!-- Delete Confirmation Modal -->
      <div
        v-if="showDeleteConfirm"
        class="fixed inset-0 bg-modal-backdrop-light dark:bg-modal-backdrop-dark flex items-center justify-center z-50"
        @click="handleDeleteCancel"
      >
        <div
          class="bg-n-background dark:bg-n-solid-2 rounded-lg p-6 max-w-md w-full mx-4 shadow-lg border border-n-weak"
          @click.stop
        >
          <h3 class="text-lg font-semibold text-n-base mb-4">
            {{ t('LIBRARY.DELETE.CONFIRM_TITLE') }}
          </h3>
          <p class="text-n-slate-11 mb-6">
            {{ t('LIBRARY.DELETE.CONFIRM_MESSAGE') }}
          </p>
          <div class="flex justify-end gap-3">
            <Button variant="outline" size="sm" @click="handleDeleteCancel">
              {{ t('LIBRARY.DELETE.CANCEL') }}
            </Button>
            <Button
              variant="danger"
              size="sm"
              :loading="isDeleting"
              @click="handleDeleteConfirm"
            >
              {{ t('LIBRARY.DELETE.CONFIRM_DELETE') }}
            </Button>
          </div>
        </div>
      </div>
    </div>
  </CardLayout>
</template>
