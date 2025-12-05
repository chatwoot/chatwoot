<script setup>
import { reactive, onMounted, ref, defineProps, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { CSAT_DISPLAY_TYPES } from 'shared/constants/messages';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import SectionLayout from 'dashboard/routes/dashboard/settings/account/components/SectionLayout.vue';
import CSATDisplayTypeSelector from './components/CSATDisplayTypeSelector.vue';
import CSATTemplate from 'dashboard/components-next/message/bubbles/Template/CSAT.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import FilterSelect from 'dashboard/components-next/filter/inputs/FilterSelect.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Switch from 'next/switch/Switch.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import languages from 'dashboard/components/widgets/conversation/advancedFilterItems/languages.js';
import ConfirmTemplateUpdateDialog from './components/ConfirmTemplateUpdateDialog.vue';
import { INBOX_TYPES } from 'dashboard/helper/inbox';

const props = defineProps({
  inbox: { type: Object, required: true },
});

const { t } = useI18n();
const store = useStore();
const labels = useMapGetter('labels/getLabels');

const isUpdating = ref(false);
const selectedLabelValues = ref([]);
const currentLabel = ref('');

const state = reactive({
  csatSurveyEnabled: false,
  displayType: 'emoji',
  message: '',
  templateButtonText: 'Please rate us',
  surveyRuleOperator: 'contains',
  templateLanguage: '',
});

const templateStatus = ref(null);
const templateLoading = ref(false);
const confirmDialog = ref(null);

const originalTemplateValues = ref({
  message: '',
  templateButtonText: '',
  templateLanguage: '',
});

const filterTypes = [
  {
    label: t('INBOX_MGMT.CSAT.SURVEY_RULE.OPERATOR.CONTAINS'),
    value: 'contains',
  },
  {
    label: t('INBOX_MGMT.CSAT.SURVEY_RULE.OPERATOR.DOES_NOT_CONTAINS'),
    value: 'does_not_contain',
  },
];

const labelOptions = computed(() =>
  labels.value?.length
    ? labels.value
        .map(label => ({ label: label.title, value: label.title }))
        .filter(label => !selectedLabelValues.value.includes(label.value))
    : []
);

const languageOptions = computed(() =>
  languages.map(({ name, id }) => ({ label: `${name} (${id})`, value: id }))
);

const isWhatsAppChannel = computed(
  () => props.inbox?.channel_type === INBOX_TYPES.WHATSAPP
);

const messagePreviewData = computed(() => ({
  content: state.message || t('INBOX_MGMT.CSAT.MESSAGE.PLACEHOLDER'),
}));

const shouldShowTemplateStatus = computed(
  () => templateStatus.value && !templateLoading.value
);

const templateApprovalStatus = computed(() => {
  const statusMap = {
    APPROVED: {
      text: t('INBOX_MGMT.CSAT.TEMPLATE_STATUS.APPROVED'),
      icon: 'i-lucide-circle-check',
      color: 'text-green-600',
    },
    PENDING: {
      text: t('INBOX_MGMT.CSAT.TEMPLATE_STATUS.PENDING'),
      icon: 'i-lucide-clock',
      color: 'text-yellow-600',
    },
    REJECTED: {
      text: t('INBOX_MGMT.CSAT.TEMPLATE_STATUS.REJECTED'),
      icon: 'i-lucide-circle-x',
      color: 'text-red-600',
    },
  };

  // Handle template not found case
  if (templateStatus.value?.error === 'TEMPLATE_NOT_FOUND') {
    return {
      text: t('INBOX_MGMT.CSAT.TEMPLATE_STATUS.NOT_FOUND'),
      icon: 'i-lucide-alert-triangle',
      color: 'text-red-600',
    };
  }

  // Handle existing template with status
  if (templateStatus.value?.template_exists && templateStatus.value.status) {
    return statusMap[templateStatus.value.status] || statusMap.PENDING;
  }

  // Default case - no template exists
  return {
    text: t('INBOX_MGMT.CSAT.TEMPLATE_STATUS.DEFAULT'),
    icon: 'i-lucide-stamp',
    color: 'text-gray-600',
  };
});

const initializeState = () => {
  if (!props.inbox) return;

  const { csat_survey_enabled, csat_config } = props.inbox;

  state.csatSurveyEnabled = csat_survey_enabled || false;

  if (!csat_config) return;

  const {
    display_type: displayType = CSAT_DISPLAY_TYPES.EMOJI,
    message = '',
    button_text: buttonText = 'Please rate us',
    language = 'en',
    survey_rules: surveyRules = {},
  } = csat_config;

  state.displayType = displayType;
  state.message = message;
  state.templateButtonText = buttonText;
  state.templateLanguage = language;
  state.surveyRuleOperator = surveyRules.operator || 'contains';

  selectedLabelValues.value = Array.isArray(surveyRules.values)
    ? [...surveyRules.values]
    : [];

  // Store original template values for change detection
  if (isWhatsAppChannel.value) {
    originalTemplateValues.value = {
      message: state.message,
      templateButtonText: state.templateButtonText,
      templateLanguage: state.templateLanguage,
    };
  }
};

const checkTemplateStatus = async () => {
  if (!isWhatsAppChannel.value) return;

  try {
    templateLoading.value = true;
    const response = await store.dispatch('inboxes/getCSATTemplateStatus', {
      inboxId: props.inbox.id,
    });

    // Handle case where template doesn't exist
    if (!response.template_exists && response.error === 'Template not found') {
      templateStatus.value = {
        template_exists: false,
        error: 'TEMPLATE_NOT_FOUND',
      };
    } else {
      templateStatus.value = response;
    }
  } catch (error) {
    templateStatus.value = {
      template_exists: false,
      error: 'API_ERROR',
    };
  } finally {
    templateLoading.value = false;
  }
};

onMounted(() => {
  initializeState();
  if (!labels.value?.length) store.dispatch('labels/get');
  if (isWhatsAppChannel.value) checkTemplateStatus();
});

watch(() => props.inbox, initializeState, { immediate: true });

const handleLabelSelect = value => {
  if (!value || selectedLabelValues.value.includes(value)) {
    return;
  }

  selectedLabelValues.value.push(value);
};

const updateDisplayType = type => {
  state.displayType = type;
};

const updateSurveyRuleOperator = operator => {
  state.surveyRuleOperator = operator;
};

const removeLabel = label => {
  const index = selectedLabelValues.value.indexOf(label);
  if (index !== -1) {
    selectedLabelValues.value.splice(index, 1);
  }
};

// Check if template-related fields have changed
const hasTemplateChanges = () => {
  if (!isWhatsAppChannel.value) return false;

  return (
    originalTemplateValues.value.message !== state.message ||
    originalTemplateValues.value.templateButtonText !==
      state.templateButtonText ||
    originalTemplateValues.value.templateLanguage !== state.templateLanguage
  );
};

// Check if there's an existing template
const hasExistingTemplate = () => {
  return (
    templateStatus.value &&
    templateStatus.value.template_exists &&
    !templateStatus.value.error
  );
};

// Check if we should create a template
const shouldCreateTemplate = () => {
  // Create template if no existing template
  if (!hasExistingTemplate()) {
    return true;
  }

  // Create template if there are changes to template fields
  return hasTemplateChanges();
};

// Build template config for saving
const buildTemplateConfig = () => {
  if (!hasExistingTemplate()) return null;

  return {
    name: templateStatus.value.template_name,
    template_id: templateStatus.value.template_id,
    language: templateStatus.value.template?.language || state.templateLanguage,
    status: templateStatus.value.status,
  };
};

const updateInbox = async attributes => {
  const payload = {
    id: props.inbox.id,
    formData: false,
    ...attributes,
  };

  return store.dispatch('inboxes/updateInbox', payload);
};

const createTemplate = async () => {
  if (!isWhatsAppChannel.value) return null;

  const response = await store.dispatch('inboxes/createCSATTemplate', {
    inboxId: props.inbox.id,
    template: {
      message: state.message,
      button_text: state.templateButtonText,
      language: state.templateLanguage,
    },
  });
  useAlert(t('INBOX_MGMT.CSAT.TEMPLATE_CREATION.SUCCESS_MESSAGE'));
  return response.template;
};

const performSave = async () => {
  try {
    isUpdating.value = true;
    let newTemplateData = null;

    // For WhatsApp channels, create template first if needed
    if (
      isWhatsAppChannel.value &&
      state.csatSurveyEnabled &&
      shouldCreateTemplate()
    ) {
      try {
        newTemplateData = await createTemplate();
      } catch (error) {
        const errorMessage =
          error.response?.data?.error ||
          t('INBOX_MGMT.CSAT.TEMPLATE_CREATION.ERROR_MESSAGE');
        useAlert(errorMessage);
        return;
      }
    }

    const csatConfig = {
      display_type: state.displayType,
      message: state.message,
      button_text: state.templateButtonText,
      language: state.templateLanguage,
      survey_rules: {
        operator: state.surveyRuleOperator,
        values: selectedLabelValues.value,
      },
    };

    // Use new template data if created, otherwise preserve existing template information
    if (newTemplateData) {
      csatConfig.template = {
        name: newTemplateData.name,
        template_id: newTemplateData.template_id,
        language: newTemplateData.language,
        status: newTemplateData.status,
        created_at: new Date().toISOString(),
      };
    } else {
      const templateConfig = buildTemplateConfig();
      if (templateConfig) {
        csatConfig.template = templateConfig;
      }
    }

    await updateInbox({
      csat_survey_enabled: state.csatSurveyEnabled,
      csat_config: csatConfig,
    });

    useAlert(t('INBOX_MGMT.CSAT.API.SUCCESS_MESSAGE'));
    checkTemplateStatus();
  } catch (error) {
    useAlert(t('INBOX_MGMT.CSAT.API.ERROR_MESSAGE'));
  } finally {
    isUpdating.value = false;
  }
};

const saveSettings = async () => {
  // Check if we need to show confirmation dialog for WhatsApp template changes
  if (
    isWhatsAppChannel.value &&
    state.csatSurveyEnabled &&
    hasExistingTemplate() &&
    hasTemplateChanges()
  ) {
    confirmDialog.value?.open();
    return;
  }

  await performSave();
};

const handleConfirmTemplateUpdate = async () => {
  // We will delete the template before creating the template
  await performSave();
};
</script>

<template>
  <div class="mx-8">
    <SectionLayout
      :title="$t('INBOX_MGMT.CSAT.TITLE')"
      :description="$t('INBOX_MGMT.CSAT.SUBTITLE')"
    >
      <template #headerActions>
        <div class="flex justify-end">
          <Switch v-model="state.csatSurveyEnabled" />
        </div>
      </template>

      <div class="grid gap-5">
        <!-- Show display type only for non-WhatsApp channels -->
        <WithLabel
          v-if="!isWhatsAppChannel"
          :label="$t('INBOX_MGMT.CSAT.DISPLAY_TYPE.LABEL')"
          name="display_type"
        >
          <CSATDisplayTypeSelector
            :selected-type="state.displayType"
            @update="updateDisplayType"
          />
        </WithLabel>

        <template v-if="isWhatsAppChannel">
          <div
            class="flex flex-col gap-4 justify-between w-full md:flex-row md:gap-6"
          >
            <div class="flex flex-col flex-1 gap-3">
              <WithLabel
                :label="$t('INBOX_MGMT.CSAT.MESSAGE.LABEL')"
                name="message"
              >
                <Editor
                  v-model="state.message"
                  :placeholder="$t('INBOX_MGMT.CSAT.MESSAGE.PLACEHOLDER')"
                  :max-length="200"
                  class="w-full"
                />
              </WithLabel>
              <Input
                v-model="state.templateButtonText"
                :label="$t('INBOX_MGMT.CSAT.BUTTON_TEXT.LABEL')"
                :placeholder="$t('INBOX_MGMT.CSAT.BUTTON_TEXT.PLACEHOLDER')"
                class="w-full"
              />

              <WithLabel
                :label="$t('INBOX_MGMT.CSAT.LANGUAGE.LABEL')"
                name="language"
              >
                <ComboBox
                  v-model="state.templateLanguage"
                  :options="languageOptions"
                  :placeholder="$t('INBOX_MGMT.CSAT.LANGUAGE.PLACEHOLDER')"
                />
              </WithLabel>

              <div
                v-if="shouldShowTemplateStatus"
                class="flex gap-2 items-center mt-4"
              >
                <Icon
                  :icon="templateApprovalStatus.icon"
                  :class="templateApprovalStatus.color"
                  class="size-4"
                />
                <span
                  :class="templateApprovalStatus.color"
                  class="text-sm font-medium"
                >
                  {{ templateApprovalStatus.text }}
                </span>
              </div>
            </div>

            <div
              class="flex flex-col justify-start items-center p-6 mt-1 rounded-xl bg-n-slate-2 outline outline-1 outline-n-weak"
            >
              <p
                class="inline-flex items-center text-sm font-medium text-n-slate-11"
              >
                {{ $t('INBOX_MGMT.CSAT.MESSAGE_PREVIEW.LABEL') }}
                <Icon
                  v-tooltip.top-end="
                    $t('INBOX_MGMT.CSAT.MESSAGE_PREVIEW.TOOLTIP')
                  "
                  icon="i-lucide-info"
                  class="flex-shrink-0 mx-1 size-4"
                />
              </p>
              <CSATTemplate
                :message="messagePreviewData"
                :button-text="state.templateButtonText"
                class="pt-12"
              />
            </div>
          </div>
        </template>

        <!-- Non-WhatsApp channels layout -->
        <template v-else>
          <WithLabel
            :label="$t('INBOX_MGMT.CSAT.MESSAGE.LABEL')"
            name="message"
          >
            <Editor
              v-model="state.message"
              :placeholder="$t('INBOX_MGMT.CSAT.MESSAGE.PLACEHOLDER')"
              :max-length="200"
              class="w-full"
            />
          </WithLabel>
        </template>

        <WithLabel
          :label="$t('INBOX_MGMT.CSAT.SURVEY_RULE.LABEL')"
          name="survey_rule"
        >
          <div class="mb-4">
            <span
              class="inline-flex flex-wrap gap-1.5 items-center text-sm text-n-slate-12"
            >
              {{ $t('INBOX_MGMT.CSAT.SURVEY_RULE.DESCRIPTION_PREFIX') }}
              <FilterSelect
                v-model="state.surveyRuleOperator"
                variant="faded"
                :options="filterTypes"
                class="inline-flex shrink-0"
                @update:model-value="updateSurveyRuleOperator"
              />
              {{ $t('INBOX_MGMT.CSAT.SURVEY_RULE.DESCRIPTION_SUFFIX') }}

              <NextButton
                v-for="label in selectedLabelValues"
                :key="label"
                sm
                faded
                slate
                trailing-icon
                :label="label"
                icon="i-lucide-x"
                class="inline-flex shrink-0"
                @click="removeLabel(label)"
              />
              <FilterSelect
                v-model="currentLabel"
                :options="labelOptions"
                :label="$t('INBOX_MGMT.CSAT.SURVEY_RULE.SELECT_PLACEHOLDER')"
                hide-label
                variant="faded"
                class="inline-flex shrink-0"
                @update:model-value="handleLabelSelect"
              />
            </span>
          </div>
        </WithLabel>
        <p class="text-sm italic text-n-slate-11">
          {{
            isWhatsAppChannel
              ? $t('INBOX_MGMT.CSAT.WHATSAPP_NOTE')
              : $t('INBOX_MGMT.CSAT.NOTE')
          }}
        </p>
        <div>
          <NextButton
            type="submit"
            :label="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
            :is-loading="isUpdating"
            @click="saveSettings"
          />
        </div>
      </div>
    </SectionLayout>

    <!-- Template Update Confirmation Dialog -->
    <ConfirmTemplateUpdateDialog
      ref="confirmDialog"
      @confirm="handleConfirmTemplateUpdate"
    />
  </div>
</template>
