<script setup>
import { reactive, computed, watch, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import WhatsAppTemplateParser from 'dashboard/components-next/whatsapp/WhatsAppTemplateParser.vue';

const emit = defineEmits(['submit', 'cancel']);
const { t } = useI18n();

const formState = {
  uiFlags: useMapGetter('schedulers/getUIFlags'),
  inboxes: useMapGetter('inboxes/getWhatsAppInboxes'),
  getFilteredWhatsAppTemplates: useMapGetter(
    'inboxes/getFilteredWhatsAppTemplates'
  ),
};

const MESSAGE_TYPE_OPTIONS = [
  { value: 'd1_reminder', label: 'D-1 Reminder' },
  { value: 'visit_guidance', label: 'Visit Guidance' },
  { value: 'happy_call_same_day', label: 'Happy Call (Same Day)' },
  { value: 'happy_call_2weeks', label: 'Happy Call (2 Weeks)' },
];

const initialState = {
  title: '',
  messageType: null,
  inboxId: null,
  templateId: null,
  description: '',
};

const state = reactive({ ...initialState });
const templateParserRef = ref(null);

const rules = {
  title: { required, minLength: minLength(1) },
  messageType: { required },
  inboxId: { required },
  templateId: { required },
};

const v$ = useVuelidate(rules, state);

const isCreating = computed(() => formState.uiFlags.value.isCreating);

const inboxOptions = computed(
  () =>
    formState.inboxes.value?.map(inbox => ({
      value: inbox.id,
      label: inbox.name,
    })) ?? []
);

const templateOptions = computed(() => {
  if (!state.inboxId) return [];
  const templates = formState.getFilteredWhatsAppTemplates.value(state.inboxId);
  return templates.map(template => {
    const friendlyName = template.name
      .replace(/_/g, ' ')
      .replace(/\b\w/g, l => l.toUpperCase());
    return {
      value: template.id,
      label: `${friendlyName} (${template.language || 'en'})`,
      template: template,
    };
  });
});

const selectedTemplate = computed(() => {
  if (!state.templateId) return null;
  return templateOptions.value.find(option => option.value === state.templateId)
    ?.template;
});

const getErrorMessage = (field, errorKey) => {
  return v$.value[field].$error
    ? t(`SCHEDULER.CREATE.FORM.${errorKey}.ERROR`)
    : '';
};

const formErrors = computed(() => ({
  title: getErrorMessage('title', 'TITLE'),
  messageType: getErrorMessage('messageType', 'MESSAGE_TYPE'),
  inbox: getErrorMessage('inboxId', 'INBOX'),
  template: getErrorMessage('templateId', 'TEMPLATE'),
}));

const isSubmitDisabled = computed(() => v$.value.$invalid);

const resetState = () => {
  Object.assign(state, initialState);
  v$.value.$reset();
};

const prepareSchedulerDetails = () => {
  const currentTemplate = selectedTemplate.value;
  const parserData = templateParserRef.value;

  const templateParams = {
    name: currentTemplate?.name || '',
    namespace: currentTemplate?.namespace || '',
    category: currentTemplate?.category || 'UTILITY',
    language: currentTemplate?.language || 'en_US',
    processed_params: parserData?.processedParams || {},
  };

  return {
    title: state.title,
    message_type: state.messageType,
    inbox_id: state.inboxId,
    description: state.description,
    template_params: templateParams,
  };
};

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) return;

  emit('submit', prepareSchedulerDetails());
  resetState();
};

watch(
  () => state.inboxId,
  () => {
    state.templateId = null;
  }
);
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
    <Input
      v-model="state.title"
      :label="t('SCHEDULER.CREATE.FORM.TITLE.LABEL')"
      :placeholder="t('SCHEDULER.CREATE.FORM.TITLE.PLACEHOLDER')"
      :message="formErrors.title"
      :message-type="formErrors.title ? 'error' : 'info'"
    />

    <div class="flex flex-col gap-1">
      <label
        for="messageType"
        class="mb-0.5 text-sm font-medium text-n-slate-12"
      >
        {{ t('SCHEDULER.CREATE.FORM.MESSAGE_TYPE.LABEL') }}
      </label>
      <ComboBox
        id="messageType"
        v-model="state.messageType"
        :options="MESSAGE_TYPE_OPTIONS"
        :has-error="!!formErrors.messageType"
        :placeholder="t('SCHEDULER.CREATE.FORM.MESSAGE_TYPE.PLACEHOLDER')"
        :message="formErrors.messageType"
        class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
      />
    </div>

    <div class="flex flex-col gap-1">
      <label for="inbox" class="mb-0.5 text-sm font-medium text-n-slate-12">
        {{ t('SCHEDULER.CREATE.FORM.INBOX.LABEL') }}
      </label>
      <ComboBox
        id="inbox"
        v-model="state.inboxId"
        :options="inboxOptions"
        :has-error="!!formErrors.inbox"
        :placeholder="t('SCHEDULER.CREATE.FORM.INBOX.PLACEHOLDER')"
        :message="formErrors.inbox"
        class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
      />
    </div>

    <div class="flex flex-col gap-1">
      <label for="template" class="mb-0.5 text-sm font-medium text-n-slate-12">
        {{ t('SCHEDULER.CREATE.FORM.TEMPLATE.LABEL') }}
      </label>
      <ComboBox
        id="template"
        v-model="state.templateId"
        :options="templateOptions"
        :has-error="!!formErrors.template"
        :placeholder="t('SCHEDULER.CREATE.FORM.TEMPLATE.PLACEHOLDER')"
        :message="formErrors.template"
        class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
      />
      <p class="mt-1 text-xs text-n-slate-11">
        {{ t('SCHEDULER.CREATE.FORM.TEMPLATE.INFO') }}
      </p>
    </div>

    <WhatsAppTemplateParser
      v-if="selectedTemplate"
      ref="templateParserRef"
      :template="selectedTemplate"
    />

    <TextArea
      v-model="state.description"
      :label="t('SCHEDULER.CREATE.FORM.DESCRIPTION.LABEL')"
      :placeholder="t('SCHEDULER.CREATE.FORM.DESCRIPTION.PLACEHOLDER')"
      rows="3"
    />

    <div class="flex gap-3 justify-between items-center w-full">
      <Button
        variant="faded"
        color="slate"
        type="button"
        :label="t('SCHEDULER.CREATE.FORM.BUTTONS.CANCEL')"
        class="w-full bg-n-alpha-2 text-n-blue-11 hover:bg-n-alpha-3"
        @click="emit('cancel')"
      />
      <Button
        :label="t('SCHEDULER.CREATE.FORM.BUTTONS.CREATE')"
        class="w-full"
        type="submit"
        :is-loading="isCreating"
        :disabled="isCreating || isSubmitDisabled"
      />
    </div>
  </form>
</template>
