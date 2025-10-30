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
import CSATTemplate from './components/CSATTemplate.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import FilterSelect from 'dashboard/components-next/filter/inputs/FilterSelect.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Switch from 'next/switch/Switch.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import languages from 'dashboard/components/widgets/conversation/advancedFilterItems/languages.js';

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
  buttonText: 'Please rate us',
  surveyRuleOperator: 'contains',
  language: '',
});

// WhatsApp template status
const templateStatus = ref(null);
const templateLoading = ref(false);

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
  languages.map(({ name, id }) => ({ label: name, value: id }))
);

const isWhatsAppChannel = computed(
  () => props.inbox?.channel_type === 'Channel::Whatsapp'
);

const messagePreviewData = computed(() => ({
  content: state.message || t('INBOX_MGMT.CSAT.MESSAGE.PLACEHOLDER'),
}));

// const templateApprovalStatus = computed(() => {
//   if (!templateStatus.value) return null;

//   switch (templateStatus.value.status) {
//     case 'APPROVED':
//       return {
//         text: t('INBOX_MGMT.CSAT.TEMPLATE_STATUS.APPROVED'),
//         icon: 'i-lucide-check-circle',
//         color: 'text-green-600',
//       };
//     case 'PENDING':
//       return {
//         text: t('INBOX_MGMT.CSAT.TEMPLATE_STATUS.PENDING'),
//         icon: 'i-lucide-clock',
//         color: 'text-yellow-600',
//       };
//     case 'REJECTED':
//       return {
//         text: t('INBOX_MGMT.CSAT.TEMPLATE_STATUS.REJECTED'),
//         icon: 'i-lucide-x-circle',
//         color: 'text-red-600',
//       };
//     default:
//       return {
//         text: t('INBOX_MGMT.CSAT.TEMPLATE_STATUS.PENDING'),
//         icon: 'i-lucide-clock',
//         color: 'text-yellow-600',
//       };
//   }
// });

const initializeState = () => {
  if (!props.inbox) return;

  const { csat_survey_enabled, csat_config } = props.inbox;

  state.csatSurveyEnabled = csat_survey_enabled || false;

  if (!csat_config) return;

  const {
    display_type: displayType = CSAT_DISPLAY_TYPES.EMOJI,
    message = '',
    button_text: buttonText = 'Please rate us',
    survey_rules: surveyRules = {},
  } = csat_config;

  state.displayType = displayType;
  state.message = message;
  state.buttonText = buttonText;
  state.surveyRuleOperator = surveyRules.operator || 'contains';

  selectedLabelValues.value = Array.isArray(surveyRules.values)
    ? [...surveyRules.values]
    : [];
};

const checkTemplateStatus = async () => {
  if (!isWhatsAppChannel.value) return;

  try {
    templateLoading.value = true;
    const response = await store.dispatch('inboxes/getCSATTemplateStatus', {
      inboxId: props.inbox.id,
    });
    templateStatus.value = response.data;
  } catch (error) {
    // console.error('Error fetching template status:', error);
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

const updateInbox = async attributes => {
  const payload = {
    id: props.inbox.id,
    formData: false,
    ...attributes,
  };

  return store.dispatch('inboxes/updateInbox', payload);
};

const createTemplate = async () => {
  if (!isWhatsAppChannel.value) return;

  try {
    isUpdating.value = true;
    await store.dispatch('inboxes/createCSATTemplate', {
      inboxId: props.inbox.id,
      template: {
        message: state.message,
        button_text: state.buttonText,
      },
    });

    // Check status after creation
    await checkTemplateStatus();
    useAlert(t('INBOX_MGMT.CSAT.TEMPLATE_CREATION.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error.response?.data?.error ||
      t('INBOX_MGMT.CSAT.TEMPLATE_CREATION.ERROR_MESSAGE');
    useAlert(errorMessage);
  } finally {
    isUpdating.value = false;
  }
};

const saveSettings = async () => {
  try {
    isUpdating.value = true;

    // For WhatsApp channels, create template first if needed
    if (isWhatsAppChannel.value && state.csatSurveyEnabled) {
      await createTemplate();
    }

    const csatConfig = {
      display_type: state.displayType,
      message: state.message,
      button_text: state.buttonText,
      survey_rules: {
        operator: state.surveyRuleOperator,
        values: selectedLabelValues.value,
      },
    };

    await updateInbox({
      csat_survey_enabled: state.csatSurveyEnabled,
      csat_config: csatConfig,
    });

    useAlert(t('INBOX_MGMT.CSAT.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('INBOX_MGMT.CSAT.API.ERROR_MESSAGE'));
  } finally {
    isUpdating.value = false;
  }
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

        <!-- WhatsApp specific layout -->
        <template v-if="isWhatsAppChannel">
          <div
            class="flex flex-col md:flex-row justify-between gap-4 md:gap-6 w-full"
          >
            <div class="flex-1 flex flex-col gap-3">
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
                v-model="state.buttonText"
                :label="$t('INBOX_MGMT.CSAT.BUTTON_TEXT.LABEL')"
                :placeholder="$t('INBOX_MGMT.CSAT.BUTTON_TEXT.PLACEHOLDER')"
                class="w-full"
              />

              <WithLabel
                :label="$t('INBOX_MGMT.CSAT.MESSAGE.LABEL')"
                name="message"
              >
                <ComboBox
                  v-model="state.language"
                  :options="languageOptions"
                  :placeholder="$t('INBOX_MGMT.CSAT.LANGUAGE.PLACEHOLDER')"
                />
              </WithLabel>

              <div class="flex gap-2 items-center mt-4">
                <Icon
                  icon="i-lucide-clock-fading"
                  class="size-4 text-n-amber-11"
                />
                <span class="text-sm font-medium text-n-amber-11">
                  {{ 'Pending WhatsApp approval' }}
                </span>
              </div>
            </div>

            <div
              class="flex flex-col items-center justify-start p-6 rounded-xl bg-n-slate-2 outline mt-1 outline-1 outline-n-weak"
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
                  class="flex-shrink-0 size-4 mx-1"
                />
              </p>
              <CSATTemplate
                :message="messagePreviewData"
                :button-text="state.buttonText"
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
          {{ $t('INBOX_MGMT.CSAT.NOTE') }}
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
  </div>
</template>
