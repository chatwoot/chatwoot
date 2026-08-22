<script setup>
import { reactive, computed, watch, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';
import { useDebounceFn } from '@vueuse/core';
import CampaignsAPI from 'dashboard/api/campaigns';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';
import WhatsAppTemplateParser from 'dashboard/components-next/whatsapp/WhatsAppTemplateParser.vue';

const props = defineProps({
  selectedCampaign: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['submit', 'cancel']);

const { t } = useI18n();

const formState = {
  uiFlags: useMapGetter('campaigns/getUIFlags'),
  labels: useMapGetter('labels/getLabels'),
  inboxes: useMapGetter('inboxes/getWhatsAppInboxes'),
  getFilteredWhatsAppTemplates: useMapGetter(
    'inboxes/getFilteredWhatsAppTemplates'
  ),
};

const initialState = {
  title: '',
  inboxId: null,
  templateId: null,
  scheduledAt: null,
  selectedAudience: [],
};

const state = reactive({ ...initialState });
const templateParserRef = ref(null);
const audiencePreview = ref({ total: 0, with_phone: 0, eligible: 0 });
const isLoadingPreview = ref(false);

const rules = {
  title: { required, minLength: minLength(1) },
  inboxId: { required },
  templateId: { required },
  scheduledAt: { required },
  selectedAudience: { required },
};

const v$ = useVuelidate(rules, state);

const isCreating = computed(
  () => formState.uiFlags.value.isCreating || formState.uiFlags.value.isUpdating
);

const isEditMode = computed(() => Boolean(props.selectedCampaign?.id));

const currentDateTime = computed(() => {
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
  return templateParserRef.value?.isFormInvalid === false;
});

const isSubmitDisabled = computed(
  () => v$.value.$invalid || !hasRequiredTemplateParams.value
);

const isDraftDisabled = computed(
  () => !state.title?.trim() || !state.inboxId || isCreating.value
);

const formatToUTCString = localDateTime =>
  localDateTime ? new Date(localDateTime).toISOString() : null;

const toLocalDateTimeInput = value => {
  if (!value) return null;
  const date =
    typeof value === 'number' ? new Date(value * 1000) : new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  const local = new Date(date.getTime() - date.getTimezoneOffset() * 60000);
  return local.toISOString().slice(0, 16);
};

const resetState = () => {
  Object.assign(state, initialState);
  audiencePreview.value = { total: 0, with_phone: 0, eligible: 0 };
  v$.value.$reset();
};

const handleCancel = () => emit('cancel');

const prepareCampaignDetails = (status = 'active') => {
  const currentTemplate = selectedTemplate.value;
  const parserData = templateParserRef.value;
  const templateContent = parserData?.renderedTemplate || '';

  const templateParams = currentTemplate
    ? {
        name: currentTemplate.name || '',
        namespace: currentTemplate.namespace || '',
        category: currentTemplate.category || 'UTILITY',
        language: currentTemplate.language || 'en_US',
        processed_params: parserData?.processedParams || {},
      }
    : props.selectedCampaign?.template_params || {};

  return {
    title: state.title,
    message: templateContent || props.selectedCampaign?.message || '',
    template_params: templateParams,
    inbox_id: state.inboxId,
    scheduled_at: formatToUTCString(state.scheduledAt),
    audience: state.selectedAudience?.map(id => ({
      id,
      type: 'Label',
    })),
    campaign_status: status,
  };
};

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid || !hasRequiredTemplateParams.value) return;

  emit('submit', prepareCampaignDetails('active'));
  resetState();
};

const handleSaveDraft = () => {
  if (isDraftDisabled.value) return;
  emit('submit', prepareCampaignDetails('draft'));
  resetState();
};

const fetchAudiencePreview = useDebounceFn(async () => {
  if (!state.inboxId || !state.selectedAudience?.length) {
    audiencePreview.value = { total: 0, with_phone: 0, eligible: 0 };
    return;
  }

  isLoadingPreview.value = true;
  try {
    const { data } = await CampaignsAPI.previewAudience({
      inboxId: state.inboxId,
      audience: state.selectedAudience.map(id => ({ id, type: 'Label' })),
    });
    audiencePreview.value = data;
  } catch {
    audiencePreview.value = { total: 0, with_phone: 0, eligible: 0 };
  } finally {
    isLoadingPreview.value = false;
  }
}, 300);

watch(
  () => state.inboxId,
  (newId, oldId) => {
    if (oldId != null && newId !== oldId) {
      state.templateId = null;
    }
    fetchAudiencePreview();
  }
);

watch(
  () => [...(state.selectedAudience || [])],
  () => fetchAudiencePreview()
);

watch(
  () => props.selectedCampaign,
  campaign => {
    if (!campaign?.id) {
      resetState();
      return;
    }

    state.title = campaign.title || '';
    state.inboxId = campaign.inbox_id || campaign.inbox?.id || null;
    state.scheduledAt = toLocalDateTimeInput(campaign.scheduled_at);
    state.selectedAudience = (campaign.audience || []).map(item => item.id);

    const templateName = campaign.template_params?.name;
    if (templateName && state.inboxId) {
      const match = templateOptions.value.find(
        option => option.template?.name === templateName
      );
      state.templateId = match?.value || null;
    }
  },
  { immediate: true }
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

    <WhatsAppTemplateParser
      v-if="selectedTemplate"
      ref="templateParserRef"
      :template="selectedTemplate"
      variable-context="campaign"
    />

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
      <p
        v-if="state.selectedAudience?.length"
        class="mt-1 text-xs text-n-slate-11"
      >
        <span v-if="isLoadingPreview">
          {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.AUDIENCE.PREVIEW_LOADING') }}
        </span>
        <span v-else>
          {{
            t('CAMPAIGN.WHATSAPP.CREATE.FORM.AUDIENCE.PREVIEW', {
              total: audiencePreview.total,
              withPhone: audiencePreview.with_phone,
              eligible: audiencePreview.eligible,
            })
          }}
        </span>
      </p>
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

    <div class="flex flex-wrap gap-3 justify-between items-center w-full">
      <Button
        variant="faded"
        color="slate"
        type="button"
        :label="t('CAMPAIGN.WHATSAPP.CREATE.FORM.BUTTONS.CANCEL')"
        class="flex-1 min-w-[6rem] bg-n-alpha-2 text-n-blue-11 hover:bg-n-alpha-3"
        @click="handleCancel"
      />
      <Button
        variant="faded"
        color="slate"
        type="button"
        :label="t('CAMPAIGN.WHATSAPP.CREATE.FORM.BUTTONS.SAVE_DRAFT')"
        class="flex-1 min-w-[6rem]"
        :is-loading="isCreating"
        :disabled="isDraftDisabled"
        @click="handleSaveDraft"
      />
      <Button
        :label="
          isEditMode
            ? t('CAMPAIGN.WHATSAPP.CREATE.FORM.BUTTONS.SCHEDULE')
            : t('CAMPAIGN.WHATSAPP.CREATE.FORM.BUTTONS.CREATE')
        "
        class="flex-1 min-w-[6rem]"
        type="submit"
        :is-loading="isCreating"
        :disabled="isCreating || isSubmitDisabled"
      />
    </div>
  </form>
</template>
