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

const emit = defineEmits(['submit', 'templateChange', 'variablesChange']);

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
const templateVariables = ref({});

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

const selectedLabels = computed(() => {
  if (!state.selectedAudience?.length) return [];
  return (
    formState.labels.value?.filter(label =>
      state.selectedAudience.includes(label.id)
    ) || []
  );
});

const totalContactsForSelectedLabels = computed(() => {
  // Mock calculation - in real implementation this would come from the API
  return selectedLabels.value.reduce((total, label) => {
    // Mock contact counts for demonstration
    const mockCounts = {
      premium: 909,
      billing: 1000,
    };
    const labelName = label.title.toLowerCase();
    return (
      total + (mockCounts[labelName] || Math.floor(Math.random() * 500) + 100)
    );
  }, 0);
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

const handleViewContacts = label => {
  // Mock function - in real implementation this would navigate to contacts filtered by label
  // eslint-disable-next-line no-console
  console.log(`Viewing contacts for label: ${label.title}`);
  // In real implementation: router.push({ name: 'contacts', query: { label: label.id } });
};

const handleVariablesUpdate = variables => {
  templateVariables.value = variables || {};
  emit('variablesChange', templateVariables.value);
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

watch(
  () => selectedTemplate.value,
  newTemplate => {
    emit('templateChange', newTemplate);
  },
  { immediate: true }
);

watch(
  () => templateVariables.value,
  newVariables => {
    emit('variablesChange', newVariables);
  },
  { deep: true }
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
        </div>

        <!-- Template Parser -->
        <WhatsAppTemplateParser
          v-if="selectedTemplate"
          ref="templateParserRef"
          :template="selectedTemplate"
          @variables-update="handleVariablesUpdate"
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

        <!-- Contact Count Information -->
        <div v-if="selectedLabels.length > 0" class="flex flex-col gap-2 mt-2">
          <!-- Individual label contact counts -->
          <div class="space-y-1">
            <div
              v-for="label in selectedLabels"
              :key="label.id"
              class="flex gap-2 items-center text-sm text-n-slate-11"
            >
              <div>
                <span class="font-medium">
                  {{ t('CAMPAIGN.FORM.CONTACT_COUNT.LABEL_PREFIX')
                  }}{{ label.title.toLowerCase() }}
                </span>
                <span>
                  {{ t('CAMPAIGN.FORM.CONTACT_COUNT.HAS_AROUND') }}
                  <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
                  {{ label.title.toLowerCase() === 'premium' ? '909' : '1000' }}
                  {{ t('CAMPAIGN.FORM.CONTACT_COUNT.CONTACTS_TAGGED') }}
                </span>
              </div>
              <Button
                :label="t('CAMPAIGN.FORM.CONTACT_COUNT.VIEW_CONTACTS')"
                variant="link"
                size="xs"
                @click="handleViewContacts(label)"
              />
            </div>
          </div>

          <!-- Total contact count -->
          <div class="p-3 mt-2 rounded-md bg-n-alpha-2">
            <p class="text-sm font-medium text-n-slate-12">
              {{ t('CAMPAIGN.FORM.CONTACT_COUNT.SENDING_TO') }}
              {{ totalContactsForSelectedLabels }}
              {{ t('CAMPAIGN.FORM.CONTACT_COUNT.CONTACTS_TOTAL') }}
            </p>
          </div>
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

    <!-- Account Health Section -->
    <Accordion :title="t('CAMPAIGN.FORM.SECTIONS.ACCOUNT_HEALTH')">
      <div class="flex flex-col gap-6 pt-4">
        <!-- Messaging Tier Card -->
        <div class="p-4 border rounded-lg bg-n-alpha-1 border-n-weak">
          <div class="flex items-start justify-between">
            <div class="flex items-center gap-2">
              <span class="i-lucide-gauge text-lg text-n-slate-10" />
              <div>
                <h4 class="text-sm font-medium text-n-slate-12">
                  {{ t('CAMPAIGN.FORM.ACCOUNT_HEALTH.MESSAGING_TIER') }}
                </h4>
                <p class="text-xs text-n-slate-11 mt-1">
                  {{ t('CAMPAIGN.FORM.ACCOUNT_HEALTH.TIER_DESCRIPTION') }}
                </p>
              </div>
            </div>
            <a
              href="https://www.zoko.io/learning-article/whatsapp-business-api-messaging-limits-and-how-to-upgrade-to-the-next-tier"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-1 text-n-blue-11 hover:text-n-blue-12 text-xs underline"
            >
              {{ t('CAMPAIGN.FORM.ACCOUNT_HEALTH.LEARN_MORE') }}
              <span class="i-lucide-external-link text-xs" />
            </a>
          </div>
        </div>

        <!-- Account Health Status -->
        <div class="p-4 border rounded-lg bg-n-alpha-1 border-n-weak">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-2">
              <span class="i-lucide-heart-pulse text-lg text-green-600" />
              <div>
                <h4 class="text-sm font-medium text-n-slate-12">
                  {{ t('CAMPAIGN.FORM.ACCOUNT_HEALTH.ACCOUNT_HEALTH') }}
                </h4>
                <p class="text-xs text-n-slate-11 mt-1">
                  {{ t('CAMPAIGN.FORM.ACCOUNT_HEALTH.QUALITY_RATING') }}
                </p>
              </div>
            </div>
            <span
              class="inline-flex items-center px-3 py-1.5 text-xs font-medium text-white bg-green-600 rounded-full"
            >
              <span class="w-1.5 h-1.5 bg-white rounded-full mr-1.5" />
              {{ t('CAMPAIGN.FORM.ACCOUNT_HEALTH.HEALTH_GREEN') }}
            </span>
          </div>
        </div>

        <!-- Account Status -->
        <div class="p-4 border rounded-lg bg-n-alpha-1 border-n-weak">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-2">
              <span class="i-lucide-wifi text-lg text-blue-600" />
              <div>
                <h4 class="text-sm font-medium text-n-slate-12">
                  {{ t('CAMPAIGN.FORM.ACCOUNT_HEALTH.ACCOUNT_STATUS') }}
                </h4>
                <p class="text-xs text-n-slate-11 mt-1">
                  {{ t('CAMPAIGN.FORM.ACCOUNT_HEALTH.API_CONNECTION') }}
                </p>
              </div>
            </div>
            <span
              class="inline-flex items-center px-3 py-1.5 text-xs font-medium text-blue-700 bg-blue-100 rounded-full"
            >
              <span class="w-1.5 h-1.5 bg-blue-600 rounded-full mr-1.5" />
              {{ t('CAMPAIGN.FORM.ACCOUNT_HEALTH.STATUS_CONNECTED') }}
            </span>
          </div>
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
