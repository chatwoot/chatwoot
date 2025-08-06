<script setup>
import { reactive, computed, watch, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';

const emit = defineEmits(['submit', 'cancel']);

const { t } = useI18n();

const formState = {
  uiFlags: useMapGetter('campaigns/getUIFlags'),
  labels: useMapGetter('labels/getLabels'),
  inboxes: useMapGetter('inboxes/getWhatsAppInboxes'),
  getWhatsAppTemplates: useMapGetter('inboxes/getWhatsAppTemplates'),
};

const initialState = {
  title: '',
  inboxId: null,
  templateId: null,
  scheduledAt: null,
  selectedAudience: [],
};

const state = reactive({ ...initialState });
const processedParams = ref({});

const rules = {
  title: { required, minLength: minLength(1) },
  inboxId: { required },
  templateId: { required },
  scheduledAt: { required },
  selectedAudience: { required },
};

const v$ = useVuelidate(rules, state);

const isCreating = computed(() => formState.uiFlags.value.isCreating);

const currentDateTime = computed(() => {
  // Added to disable the scheduled at field from being set to the current time
  const now = new Date();
  const localTime = new Date(now.getTime() - now.getTimezoneOffset() * 60000);
  return localTime.toISOString().slice(0, 16);
});

const mapToOptions = (items, valueKey, labelKey) =>
  items?.map(item => ({
    value: item[valueKey],
    label: item[labelKey],
  })) ?? [];

const audienceList = computed(() =>
  mapToOptions(formState.labels.value, 'id', 'title')
);

const inboxOptions = computed(() =>
  mapToOptions(formState.inboxes.value, 'id', 'name')
);

const templateOptions = computed(() => {
  if (!state.inboxId) return [];
  const templates = formState.getWhatsAppTemplates.value(state.inboxId);
  return templates.map(template => {
    // Create a more user-friendly label from template name
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

const templateString = computed(() => {
  if (!selectedTemplate.value) return '';
  try {
    return (
      selectedTemplate.value.components?.find(
        component => component.type === 'BODY'
      )?.text || ''
    );
  } catch (error) {
    return '';
  }
});

const processedString = computed(() => {
  if (!templateString.value) return '';
  return templateString.value.replace(/{{([^}]+)}}/g, (match, variable) => {
    return processedParams.value[variable] || `{{${variable}}}`;
  });
});

const getErrorMessage = (field, errorKey) => {
  const baseKey = 'CAMPAIGN.WHATSAPP.CREATE.FORM';
  return v$.value[field].$error ? t(`${baseKey}.${errorKey}.ERROR`) : '';
};

const formErrors = computed(() => ({
  title: getErrorMessage('title', 'TITLE'),
  inbox: getErrorMessage('inboxId', 'INBOX'),
  template: getErrorMessage('templateId', 'TEMPLATE'),
  scheduledAt: getErrorMessage('scheduledAt', 'SCHEDULED_AT'),
  audience: getErrorMessage('selectedAudience', 'AUDIENCE'),
}));

const hasRequiredTemplateParams = computed(() => {
  const params = Object.values(processedParams.value);
  return params.length === 0 || params.every(param => param.trim() !== '');
});

const isSubmitDisabled = computed(
  () => v$.value.$invalid || !hasRequiredTemplateParams.value
);

const formatToUTCString = localDateTime =>
  localDateTime ? new Date(localDateTime).toISOString() : null;

const resetState = () => {
  Object.assign(state, initialState);
  processedParams.value = {};
  v$.value.$reset();
};

const handleCancel = () => emit('cancel');

const generateVariables = () => {
  const matchedVariables = templateString.value.match(/{{([^}]+)}}/g);
  if (!matchedVariables) {
    processedParams.value = {};
    return;
  }

  const finalVars = matchedVariables.map(match => match.replace(/{{|}}/g, ''));
  processedParams.value = finalVars.reduce((acc, variable) => {
    acc[variable] = processedParams.value[variable] || '';
    return acc;
  }, {});
};

const prepareCampaignDetails = () => {
  // Find the selected template to get its content
  const currentTemplate = selectedTemplate.value;

  // Extract template content - this should be the template message body
  const templateContent = templateString.value;

  // Prepare template_params object with the same structure as used in contacts
  const templateParams = {
    name: currentTemplate?.name || '',
    namespace: currentTemplate?.namespace || '',
    category: currentTemplate?.category || 'UTILITY',
    language: currentTemplate?.language || 'en_US',
    processed_params: processedParams.value,
  };

  return {
    title: state.title,
    message: templateContent,
    template_params: templateParams,
    inbox_id: state.inboxId,
    scheduled_at: formatToUTCString(state.scheduledAt),
    audience: state.selectedAudience?.map(id => ({
      id,
      type: 'Label',
    })),
  };
};

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) return;

  emit('submit', prepareCampaignDetails());
  resetState();
  handleCancel();
};

// Reset template selection when inbox changes
watch(
  () => state.inboxId,
  () => {
    state.templateId = null;
    processedParams.value = {};
  }
);

// Generate variables when template changes
watch(
  () => state.templateId,
  () => {
    generateVariables();
  }
);
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
    <Input
      v-model="state.title"
      :label="t('CAMPAIGN.WHATSAPP.CREATE.FORM.TITLE.LABEL')"
      :placeholder="t('CAMPAIGN.WHATSAPP.CREATE.FORM.TITLE.PLACEHOLDER')"
      :message="formErrors.title"
      :message-type="formErrors.title ? 'error' : 'info'"
    />

    <div class="flex flex-col gap-1">
      <label for="inbox" class="mb-0.5 text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.INBOX.LABEL') }}
      </label>
      <ComboBox
        id="inbox"
        v-model="state.inboxId"
        :options="inboxOptions"
        :has-error="!!formErrors.inbox"
        :placeholder="t('CAMPAIGN.WHATSAPP.CREATE.FORM.INBOX.PLACEHOLDER')"
        :message="formErrors.inbox"
        class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
      />
    </div>

    <div class="flex flex-col gap-1">
      <label for="template" class="mb-0.5 text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEMPLATE.LABEL') }}
      </label>
      <ComboBox
        id="template"
        v-model="state.templateId"
        :options="templateOptions"
        :has-error="!!formErrors.template"
        :placeholder="t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEMPLATE.PLACEHOLDER')"
        :message="formErrors.template"
        class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
      />
      <p class="mt-1 text-xs text-n-slate-11">
        {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEMPLATE.INFO') }}
      </p>
    </div>

    <!-- Template Preview -->
    <div
      v-if="selectedTemplate"
      class="flex flex-col gap-4 p-4 rounded-lg bg-n-alpha-black2"
    >
      <div class="flex justify-between items-center">
        <h3 class="text-sm font-medium text-n-slate-12">
          {{ selectedTemplate.name }}
        </h3>
        <span class="text-xs text-n-slate-11">
          {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEMPLATE.LANGUAGE') }}:
          {{ selectedTemplate.language || 'en' }}
        </span>
      </div>

      <div class="flex flex-col gap-2">
        <div class="rounded-md bg-n-alpha-black3">
          <div class="text-sm whitespace-pre-wrap text-n-slate-12">
            {{ processedString }}
          </div>
        </div>
      </div>

      <div class="text-xs text-n-slate-11">
        {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEMPLATE.CATEGORY') }}:
        {{ selectedTemplate.category || 'UTILITY' }}
      </div>
    </div>

    <!-- Template Variables -->
    <div
      v-if="Object.keys(processedParams).length > 0"
      class="flex flex-col gap-3"
    >
      <label class="text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEMPLATE.VARIABLES_LABEL') }}
      </label>
      <div class="flex flex-col gap-2">
        <div
          v-for="(value, key) in processedParams"
          :key="key"
          class="flex gap-2 items-center"
        >
          <Input
            v-model="processedParams[key]"
            type="text"
            class="flex-1"
            :placeholder="
              t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEMPLATE.VARIABLE_PLACEHOLDER', {
                variable: key,
              })
            "
          />
        </div>
      </div>
    </div>

    <div class="flex flex-col gap-1">
      <label for="audience" class="mb-0.5 text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.AUDIENCE.LABEL') }}
      </label>
      <TagMultiSelectComboBox
        v-model="state.selectedAudience"
        :options="audienceList"
        :label="t('CAMPAIGN.WHATSAPP.CREATE.FORM.AUDIENCE.LABEL')"
        :placeholder="t('CAMPAIGN.WHATSAPP.CREATE.FORM.AUDIENCE.PLACEHOLDER')"
        :has-error="!!formErrors.audience"
        :message="formErrors.audience"
        class="[&>div>button]:bg-n-alpha-black2"
      />
    </div>

    <Input
      v-model="state.scheduledAt"
      :label="t('CAMPAIGN.WHATSAPP.CREATE.FORM.SCHEDULED_AT.LABEL')"
      type="datetime-local"
      :min="currentDateTime"
      :placeholder="t('CAMPAIGN.WHATSAPP.CREATE.FORM.SCHEDULED_AT.PLACEHOLDER')"
      :message="formErrors.scheduledAt"
      :message-type="formErrors.scheduledAt ? 'error' : 'info'"
    />

    <div class="flex gap-3 justify-between items-center w-full">
      <Button
        variant="faded"
        color="slate"
        type="button"
        :label="t('CAMPAIGN.WHATSAPP.CREATE.FORM.BUTTONS.CANCEL')"
        class="w-full bg-n-alpha-2 text-n-blue-text hover:bg-n-alpha-3"
        @click="handleCancel"
      />
      <Button
        :label="t('CAMPAIGN.WHATSAPP.CREATE.FORM.BUTTONS.CREATE')"
        class="w-full"
        type="submit"
        :is-loading="isCreating"
        :disabled="isCreating || isSubmitDisabled"
      />
    </div>
  </form>
</template>
