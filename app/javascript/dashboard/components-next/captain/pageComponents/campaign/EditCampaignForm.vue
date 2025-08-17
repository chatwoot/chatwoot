<script setup>
import { reactive, computed, watch, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import Accordion from 'dashboard/components-next/Accordion/Accordion.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';
import WhatsAppTemplateParser from 'dashboard/components-next/whatsapp/WhatsAppTemplateParser.vue';

const props = defineProps({
  mode: {
    type: String,
    required: true,
    validator: value => ['edit', 'create'].includes(value),
  },
  campaign: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['submit']);

const { t } = useI18n();

const formState = {
  uiFlags: useMapGetter('campaigns/getUIFlags'),
  labels: useMapGetter('labels/getLabels'),
  getFilteredWhatsAppTemplates: useMapGetter(
    'inboxes/getFilteredWhatsAppTemplates'
  ),
};

const initialState = {
  title: '',
  description: '',
  message: '',
  templateId: null,
  selectedAudience: [],
  scheduledAt: null,
  campaignType: 'ongoing',
};

const state = reactive({ ...initialState });
const templateParserRef = ref(null);

const validationRules = {
  title: { required, minLength: minLength(1) },
  templateId: { required },
  selectedAudience: { required },
};

const v$ = useVuelidate(validationRules, state);

const isLoading = computed(() => formState.uiFlags.value.creatingItem);

const getErrorMessage = field => {
  return v$.value[field].$error ? v$.value[field].$errors[0].$message : '';
};

const formErrors = computed(() => ({
  title: getErrorMessage('title'),
  template: getErrorMessage('templateId'),
  audience: getErrorMessage('selectedAudience'),
}));

const templateOptions = computed(() => {
  if (!props.campaign.inbox.id) return [];
  const templates = formState.getFilteredWhatsAppTemplates.value(
    props.campaign.inbox.id
  );
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

const audienceList = computed(() => {
  return (
    formState.labels.value?.map(label => ({
      value: label.id,
      label: label.title,
    })) ?? []
  );
});

const updateStateFromCampaign = campaign => {
  state.title = campaign.title || '';
  state.description = campaign.description || '';
  state.message = campaign.message || '';
  state.templateId = campaign.template_params?.name
    ? templateOptions.value.find(
        opt => opt.template.name === campaign.template_params.name
      )?.value || null
    : null;
  state.selectedAudience = campaign.audience?.map(aud => aud.id) || [];
  state.scheduledAt = campaign.scheduled_at || null;
  state.campaignType = campaign.campaign_type || 'ongoing';
};

const handleBasicDetailsUpdate = async () => {
  const result = await Promise.all([v$.value.title.$validate()]).then(results =>
    results.every(Boolean)
  );
  if (!result) return;

  const payload = {
    title: state.title,
    description: state.description,
  };

  emit('submit', payload);
};

const handleSelectTemplateUpdate = async () => {
  const result = await v$.value.templateId.$validate();
  if (!result) return;

  const currentTemplate = selectedTemplate.value;
  const parserData = templateParserRef.value;

  const templateContent = parserData?.renderedTemplate || '';
  const templateParams = {
    name: currentTemplate?.name || '',
    namespace: currentTemplate?.namespace || '',
    category: currentTemplate?.category || 'UTILITY',
    language: currentTemplate?.language || 'en_US',
    processed_params: parserData?.processedParams || {},
  };

  const payload = {
    message: templateContent,
    template_params: templateParams,
  };

  emit('submit', payload);
};

const handleSelectAudienceUpdate = async () => {
  const result = await v$.value.selectedAudience.$validate();
  if (!result) return;

  const payload = {
    audience: state.selectedAudience?.map(id => ({
      id,
      type: 'Label',
    })),
  };

  emit('submit', payload);
};

const handleScheduleTemplateUpdate = () => {
  const payload = {
    scheduled_at: state.scheduledAt,
    campaign_type: state.campaignType,
  };

  emit('submit', payload);
};

watch(
  () => props.campaign,
  newCampaign => {
    if (props.mode === 'edit' && newCampaign) {
      updateStateFromCampaign(newCampaign);
    }
  },
  { immediate: true }
);
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
    <!-- Basic Details Section -->
    <Accordion :title="t('CAMPAIGN.FORM.SECTIONS.BASIC_DETAILS')" is-open>
      <div class="flex flex-col gap-4 pt-4">
        <Input
          v-model="state.title"
          :label="t('CAMPAIGN.FORM.TITLE.LABEL')"
          :placeholder="t('CAMPAIGN.FORM.TITLE.PLACEHOLDER')"
          :message="formErrors.title"
          :message-type="formErrors.title ? 'error' : 'info'"
        />

        <Editor
          v-model="state.description"
          :label="t('CAMPAIGN.FORM.DESCRIPTION.LABEL')"
          :placeholder="t('CAMPAIGN.FORM.DESCRIPTION.PLACEHOLDER')"
        />

        <div class="flex justify-end">
          <Button
            size="small"
            :loading="isLoading"
            @click="handleBasicDetailsUpdate"
          >
            {{ t('CAMPAIGN.FORM.UPDATE') }}
          </Button>
        </div>
      </div>
    </Accordion>

    <!-- Select Template Section -->
    <Accordion :title="t('CAMPAIGN.FORM.SECTIONS.SELECT_TEMPLATE')">
      <div class="flex flex-col gap-4 pt-4">
        <div class="flex flex-col gap-1">
          <label
            for="template"
            class="mb-0.5 text-sm font-medium text-n-slate-12"
          >
            {{ t('CAMPAIGN.FORM.TEMPLATE.LABEL') }}
          </label>
          <ComboBox
            id="template"
            v-model="state.templateId"
            :options="templateOptions"
            :has-error="!!formErrors.template"
            :placeholder="t('CAMPAIGN.FORM.TEMPLATE.SELECT')"
            :message="formErrors.template"
            class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
          />
          <p class="mt-1 text-xs text-n-slate-11">
            {{ t('CAMPAIGN.FORM.TEMPLATE.INFO') }}
          </p>
          <div class="mt-4 text-xs italic text-gray-500">
            {{ t('CAMPAIGN.PLAYGROUND.PREVIEW_NOTE') }}
          </div>
        </div>

        <!-- Template Parser -->
        <WhatsAppTemplateParser
          v-if="selectedTemplate"
          ref="templateParserRef"
          :template="selectedTemplate"
        />

        <div class="flex justify-end">
          <Button
            size="small"
            :loading="isLoading"
            @click="handleSelectTemplateUpdate"
          >
            {{ t('CAMPAIGN.FORM.UPDATE') }}
          </Button>
        </div>
      </div>
    </Accordion>

    <!-- Select Audience Section -->
    <Accordion :title="t('CAMPAIGN.FORM.SECTIONS.SELECT_AUDIENCE')">
      <div class="flex flex-col gap-4 pt-4">
        <div class="flex flex-col gap-1">
          <label
            for="audience"
            class="mb-0.5 text-sm font-medium text-n-slate-12"
          >
            {{ t('CAMPAIGN.FORM.AUDIENCE.LABEL') }}
          </label>
          <TagMultiSelectComboBox
            v-model="state.selectedAudience"
            :options="audienceList"
            :label="t('CAMPAIGN.FORM.AUDIENCE.LABEL')"
            :placeholder="t('CAMPAIGN.FORM.AUDIENCE.SELECT')"
            :has-error="!!formErrors.audience"
            :message="formErrors.audience"
            class="[&>div>button]:bg-n-alpha-black2"
          />
        </div>

        <div class="flex justify-end">
          <Button
            size="small"
            :loading="isLoading"
            @click="handleSelectAudienceUpdate"
          >
            {{ t('CAMPAIGN.FORM.UPDATE') }}
          </Button>
        </div>
      </div>
    </Accordion>

    <!-- Schedule Template Section -->
    <Accordion :title="t('CAMPAIGN.FORM.SECTIONS.SCHEDULE_TEMPLATE')">
      <div class="flex flex-col gap-4 pt-4">
        <div class="flex flex-col gap-2">
          <label class="text-sm font-medium text-n-slate-12">
            {{ t('CAMPAIGN.FORM.SCHEDULED_AT.LABEL') }}
          </label>
          <input
            v-model="state.scheduledAt"
            type="datetime-local"
            class="p-2 w-full rounded-md border"
          />
        </div>

        <div class="flex justify-end">
          <Button
            size="small"
            :loading="isLoading"
            @click="handleScheduleTemplateUpdate"
          >
            {{ t('CAMPAIGN.FORM.UPDATE') }}
          </Button>
        </div>
      </div>
    </Accordion>
  </form>
</template>
