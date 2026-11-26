<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { INBOX_TYPES } from 'dashboard/helper/inbox';

import Button from 'dashboard/components-next/button/Button.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Modal from 'dashboard/components/Modal.vue';
import CannedResponseFiles from './CannedResponseFiles.vue';
import CannedResponsePreview from './CannedResponsePreview.vue';

const props = defineProps({
  cannedResponse: { type: Object, default: () => ({}) },
});

const emit = defineEmits(['close']);

const { t } = useI18n();
const store = useStore();
const inboxes = useMapGetter('inboxes/getInboxes');

const shortCode = ref(props.cannedResponse.short_code ?? '');
const content = ref(props.cannedResponse.content ?? '');
const files = ref(props.cannedResponse.files ?? []);
const isSaving = ref(false);
const pendingImageUploads = ref(0);

const v$ = useVuelidate(
  {
    shortCode: { required, minLength: minLength(2) },
    content: { required },
  },
  { shortCode, content }
);

const isEditing = computed(() => !!props.cannedResponse.id);

// X inboxes can no longer be added, so one left from before gets no preview
const previewInboxes = computed(() =>
  inboxes.value.filter(inbox => inbox.channel_type !== INBOX_TYPES.TWITTER)
);

const title = computed(() =>
  isEditing.value
    ? `${t('CANNED_MGMT.EDIT.TITLE')} - ${props.cannedResponse.short_code}`
    : t('CANNED_MGMT.ADD.TITLE')
);

const canSave = computed(
  () =>
    !v$.value.$invalid &&
    !isSaving.value &&
    !pendingImageUploads.value &&
    files.value.every(file => file.signed_id)
);

const onImageUpload = isUploading => {
  pendingImageUploads.value += isUploading ? 1 : -1;
};

const save = async () => {
  if (!canSave.value) return;

  const payload = {
    short_code: shortCode.value,
    content: content.value,
    files: files.value.map(file => file.signed_id),
  };

  isSaving.value = true;
  try {
    if (isEditing.value) {
      await store.dispatch('updateCannedResponse', {
        id: props.cannedResponse.id,
        ...payload,
      });
      useAlert(t('CANNED_MGMT.EDIT.API.SUCCESS_MESSAGE'));
    } else {
      await store.dispatch('createCannedResponse', payload);
      useAlert(t('CANNED_MGMT.ADD.API.SUCCESS_MESSAGE'));
    }
    emit('close');
  } catch (error) {
    const fallbackMessage = isEditing.value
      ? t('CANNED_MGMT.EDIT.API.ERROR_MESSAGE')
      : t('CANNED_MGMT.ADD.API.ERROR_MESSAGE');
    useAlert(error?.message || fallbackMessage);
  } finally {
    isSaving.value = false;
  }
};
</script>

<template>
  <Modal show size="medium" @close="emit('close')">
    <div class="flex flex-col gap-6 p-6">
      <div class="flex flex-col gap-2">
        <h3 class="text-heading-2 text-n-slate-12">
          {{ title }}
        </h3>
        <p v-if="!isEditing" class="mb-0 text-body-para text-n-slate-11">
          {{ t('CANNED_MGMT.ADD.DESC') }}
        </p>
      </div>
      <div class="flex flex-col gap-6 lg:flex-row">
        <div class="flex flex-col flex-1 min-w-0 gap-4">
          <Input
            v-model="v$.shortCode.$model"
            :label="t('CANNED_MGMT.ADD.FORM.SHORT_CODE.LABEL')"
            :placeholder="t('CANNED_MGMT.ADD.FORM.SHORT_CODE.PLACEHOLDER')"
            :message-type="v$.shortCode.$error ? 'error' : 'info'"
            @enter="save"
          />
          <Editor
            v-model="v$.content.$model"
            class="[&_.ProseMirror-woot-style]:!min-h-[10rem]"
            :label="t('CANNED_MGMT.ADD.FORM.CONTENT.LABEL')"
            :placeholder="t('CANNED_MGMT.ADD.FORM.CONTENT.PLACEHOLDER')"
            :message-type="v$.content.$error ? 'error' : 'info'"
            :show-character-count="false"
            :enable-canned-responses="false"
            enable-variables
            channel-type="Context::CannedResponse"
            @toggle-image-upload="onImageUpload"
          />
          <CannedResponseFiles v-model="files" />
          <p class="mb-0 text-label-small text-n-slate-11">
            {{ t('CANNED_MGMT.FILES.NOTE') }}
          </p>
        </div>
        <CannedResponsePreview
          v-if="previewInboxes.length"
          :inboxes="previewInboxes"
          :content="content"
          :files="files"
        />
      </div>
      <div class="flex justify-end gap-2">
        <Button
          faded
          slate
          :label="t('CANNED_MGMT.ADD.CANCEL_BUTTON_TEXT')"
          @click="emit('close')"
        />
        <Button
          :label="t('CANNED_MGMT.ADD.FORM.SUBMIT')"
          :disabled="!canSave"
          :is-loading="isSaving"
          @click="save"
        />
      </div>
    </div>
  </Modal>
</template>
