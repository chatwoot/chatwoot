<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Textarea from 'dashboard/components-next/textarea/Textarea.vue';

const props = defineProps({
  resource: { type: Object, default: () => ({}) },
  isLoading: { type: Boolean, default: false },
});

const emit = defineEmits(['save', 'cancel']);

const { t } = useI18n();

const form = ref({
  title: '',
  description: '',
  content: '',
});

// Watch for changes in resource prop and update form
watch(
  () => props.resource,
  newResource => {
    if (newResource) {
      form.value = {
        title: newResource.title || '',
        description: newResource.description || '',
        content: newResource.content || '',
      };
    }
  },
  { immediate: true }
);

const isValid = computed(() => {
  return (
    form.value.title.trim() &&
    form.value.description.trim() &&
    form.value.content.trim()
  );
});

const handleSave = () => {
  if (isValid.value) {
    emit('save', { ...form.value });
  }
};

const handleCancel = () => {
  emit('cancel');
};
</script>

<template>
  <div class="flex flex-col gap-6 p-6">
    <div class="flex items-center justify-between">
      <h2 class="text-xl font-semibold text-n-base">
        {{
          resource?.id
            ? t('LIBRARY.FORM.EDIT_TITLE')
            : t('LIBRARY.FORM.ADD_TITLE')
        }}
      </h2>
    </div>

    <form class="flex flex-col gap-4" @submit.prevent="handleSave">
      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ t('LIBRARY.FORM.TITLE_LABEL') }}
        </label>
        <Input
          v-model="form.title"
          :placeholder="t('LIBRARY.FORM.TITLE_PLACEHOLDER')"
          required
        />
      </div>

      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ t('LIBRARY.FORM.DESCRIPTION_LABEL') }}
        </label>
        <Textarea
          v-model="form.description"
          :placeholder="t('LIBRARY.FORM.DESCRIPTION_PLACEHOLDER')"
          rows="3"
          required
        />
      </div>

      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ t('LIBRARY.FORM.CONTENT_LABEL') }}
        </label>
        <Textarea
          v-model="form.content"
          :placeholder="t('LIBRARY.FORM.CONTENT_PLACEHOLDER')"
          rows="10"
          required
        />
      </div>

      <div class="flex justify-end gap-3 pt-4 border-t border-n-weak">
        <Button variant="outline" :disabled="isLoading" @click="handleCancel">
          {{ t('LIBRARY.FORM.CANCEL') }}
        </Button>
        <Button
          type="submit"
          :disabled="!isValid || isLoading"
          :loading="isLoading"
        >
          {{ resource?.id ? t('LIBRARY.FORM.UPDATE') : t('LIBRARY.FORM.SAVE') }}
        </Button>
      </div>
    </form>
  </div>
</template>
