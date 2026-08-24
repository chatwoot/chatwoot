<script setup>
import { reactive, computed, ref, nextTick, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import {
  CAMPAIGN_MESSAGE_VARIABLES,
  insertVariableAtCursor,
  renderWithSampleValues,
} from 'dashboard/helper/campaignHelper';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import VariableChips from 'dashboard/components-next/Campaigns/VariableChips.vue';

const props = defineProps({
  selectedTemplate: {
    type: Object,
    default: null,
  },
});

const { t } = useI18n();
const store = useStore();

const dialogRef = ref(null);
const bodyRef = ref(null);

const uiFlags = useMapGetter('campaignTemplates/getUIFlags');

const state = reactive({
  name: '',
  body: '',
});

const rules = {
  name: { required, minLength: minLength(1) },
  body: { required, minLength: minLength(1) },
};

const v$ = useVuelidate(rules, state);

const isEditMode = computed(() => Boolean(props.selectedTemplate?.id));
const isSaving = computed(() =>
  isEditMode.value ? uiFlags.value.isUpdating : uiFlags.value.isCreating
);

const formErrors = computed(() => ({
  name: v$.value.name.$error ? t('CAMPAIGN.TEMPLATES.FORM.NAME.ERROR') : '',
  body: v$.value.body.$error ? t('CAMPAIGN.TEMPLATES.FORM.BODY.ERROR') : '',
}));

const sampleValues = computed(() =>
  Object.fromEntries(
    CAMPAIGN_MESSAGE_VARIABLES.map(({ key, name }) => [
      name,
      t(`CAMPAIGN.TEMPLATES.FORM.PREVIEW.SAMPLE.${key}`),
    ])
  )
);

const previewBody = computed(() =>
  renderWithSampleValues(state.body, sampleValues.value)
);

const handleInsertVariable = token => {
  const element = bodyRef.value?.textareaRef;
  const { value, cursorPosition } = insertVariableAtCursor(
    element,
    state.body,
    token
  );
  state.body = value;

  nextTick(() => {
    element?.focus();
    element?.setSelectionRange(cursorPosition, cursorPosition);
  });
};

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) return;

  try {
    if (isEditMode.value) {
      await store.dispatch('campaignTemplates/update', {
        id: props.selectedTemplate.id,
        name: state.name,
        body: state.body,
      });
      useAlert(t('CAMPAIGN.TEMPLATES.FORM.API.UPDATE_SUCCESS_MESSAGE'));
    } else {
      await store.dispatch('campaignTemplates/create', {
        name: state.name,
        body: state.body,
      });
      useAlert(t('CAMPAIGN.TEMPLATES.FORM.API.SUCCESS_MESSAGE'));
    }

    dialogRef.value.close();
  } catch (error) {
    useAlert(t('CAMPAIGN.TEMPLATES.FORM.API.ERROR_MESSAGE'));
  }
};

watch(
  () => props.selectedTemplate,
  template => {
    Object.assign(state, {
      name: template?.name ?? '',
      body: template?.body ?? '',
    });
    v$.value.$reset();
  },
  { immediate: true }
);

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    width="xl"
    overflow-y-auto
    :title="
      isEditMode
        ? t('CAMPAIGN.TEMPLATES.EDIT.TITLE')
        : t('CAMPAIGN.TEMPLATES.CREATE.TITLE')
    "
    :confirm-button-label="t('CAMPAIGN.TEMPLATES.FORM.BUTTONS.SAVE')"
    :is-loading="isSaving"
    :disable-confirm-button="isSaving"
    @confirm="handleSubmit"
  >
    <div class="flex flex-col gap-4">
      <Input
        v-model="state.name"
        :label="t('CAMPAIGN.TEMPLATES.FORM.NAME.LABEL')"
        :placeholder="t('CAMPAIGN.TEMPLATES.FORM.NAME.PLACEHOLDER')"
        :message="formErrors.name"
        :message-type="formErrors.name ? 'error' : 'info'"
      />

      <TextArea
        ref="bodyRef"
        v-model="state.body"
        :label="t('CAMPAIGN.TEMPLATES.FORM.BODY.LABEL')"
        :placeholder="t('CAMPAIGN.TEMPLATES.FORM.BODY.PLACEHOLDER')"
        :max-length="640"
        show-character-count
        :message="formErrors.body"
        :message-type="formErrors.body ? 'error' : 'info'"
      />

      <VariableChips @insert="handleInsertVariable" />

      <div class="flex flex-col gap-1.5">
        <span class="text-xs text-n-slate-11">
          {{ t('CAMPAIGN.TEMPLATES.FORM.PREVIEW.LABEL') }}
        </span>
        <p
          class="p-3 mb-0 text-sm whitespace-pre-wrap rounded-lg text-n-slate-12 bg-n-alpha-black2"
        >
          {{ previewBody || t('CAMPAIGN.TEMPLATES.FORM.PREVIEW.EMPTY') }}
        </p>
      </div>
    </div>
  </Dialog>
</template>
