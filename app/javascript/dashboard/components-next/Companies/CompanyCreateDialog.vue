<script setup>
import { computed, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';

defineProps({
  isLoading: { type: Boolean, default: false },
});

const emit = defineEmits(['create']);

const { t } = useI18n();
const dialogRef = ref(null);

const form = reactive({ name: '', domain: '', description: '' });

const isFormInvalid = computed(() => !form.name.trim());

const resetForm = () => {
  form.name = '';
  form.domain = '';
  form.description = '';
};

const handleConfirm = () => {
  if (isFormInvalid.value) return;

  emit('create', {
    name: form.name.trim(),
    domain: form.domain.trim() || null,
    description: form.description.trim() || null,
  });
};

const closeDialog = () => {
  dialogRef.value?.close();
};

const onSuccess = () => {
  resetForm();
  closeDialog();
};

defineExpose({ dialogRef, onSuccess });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="3xl"
    overflow-y-auto
    @confirm="handleConfirm"
    @close="resetForm"
  >
    <div class="flex flex-col gap-6">
      <div class="flex flex-col items-start gap-2">
        <span class="py-1 text-sm font-medium text-n-slate-12">
          {{ t('COMPANIES.CREATE.TITLE') }}
        </span>
        <div class="grid w-full grid-cols-1 gap-4 sm:grid-cols-2">
          <Input
            v-model="form.name"
            :placeholder="t('COMPANIES.DETAIL.PROFILE.FIELDS.NAME')"
            :disabled="isLoading"
            custom-input-class="h-8 !pt-1 !pb-1 [&:not(.error,.focus)]:!outline-transparent"
            autofocus
          />
          <Input
            v-model="form.domain"
            :placeholder="t('COMPANIES.DETAIL.PROFILE.FIELDS.DOMAIN')"
            :disabled="isLoading"
            custom-input-class="h-8 !pt-1 !pb-1 [&:not(.error,.focus)]:!outline-transparent"
          />
        </div>
      </div>
      <TextArea
        v-model="form.description"
        :placeholder="t('COMPANIES.DETAIL.PROFILE.DESCRIPTION_PLACEHOLDER')"
        :disabled="isLoading"
        :max-length="280"
        class="w-full"
        show-character-count
        auto-height
      />
    </div>

    <template #footer>
      <div class="flex items-center justify-between w-full gap-3">
        <Button
          :label="t('DIALOG.BUTTONS.CANCEL')"
          variant="link"
          type="reset"
          class="h-10 hover:!no-underline hover:text-n-brand"
          @click="closeDialog"
        />
        <Button
          :label="t('COMPANIES.CREATE.ACTIONS.SAVE')"
          color="blue"
          type="submit"
          :disabled="isFormInvalid || isLoading"
          :is-loading="isLoading"
        />
      </div>
    </template>
  </Dialog>
</template>
