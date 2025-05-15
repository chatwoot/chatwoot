<script setup>
import { reactive, onMounted, ref, defineProps, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { CSAT_DISPLAY_TYPES } from 'shared/constants/messages';

import SettingsSection from 'dashboard/components/SettingsSection.vue';
import CSATDisplayTypeSelector from './components/CSATDisplayTypeSelector.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import FilterSelect from 'dashboard/components-next/filter/inputs/FilterSelect.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

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
  surveyRuleOperator: 'contains',
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

const initializeState = () => {
  if (!props.inbox) return;

  const { csat_survey_enabled, csat_config } = props.inbox;

  state.csatSurveyEnabled = csat_survey_enabled || false;

  if (!csat_config) return;

  const {
    display_type: displayType = CSAT_DISPLAY_TYPES.EMOJI,
    message = '',
    survey_rules: surveyRules = {},
  } = csat_config;

  state.displayType = displayType;
  state.message = message;
  state.surveyRuleOperator = surveyRules.operator || 'contains';

  selectedLabelValues.value = Array.isArray(surveyRules.values)
    ? [...surveyRules.values]
    : [];
};

onMounted(() => {
  initializeState();
  if (!labels.value?.length) store.dispatch('labels/get');
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

const saveSettings = async () => {
  try {
    isUpdating.value = true;

    const csatConfig = {
      display_type: state.displayType,
      message: state.message,
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
    <SettingsSection
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.ENABLE_CSAT')"
      :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.ENABLE_CSAT_SUB_TEXT')"
    >
      <select v-model="state.csatSurveyEnabled" class="max-w-56">
        <option :value="true">
          {{ $t('INBOX_MGMT.EDIT.ENABLE_CSAT.ENABLED') }}
        </option>
        <option :value="false">
          {{ $t('INBOX_MGMT.EDIT.ENABLE_CSAT.DISABLED') }}
        </option>
      </select>
    </SettingsSection>

    <div v-if="state.csatSurveyEnabled">
      <SettingsSection
        :title="$t('INBOX_MGMT.CSAT.DISPLAY_TYPE.LABEL')"
        :sub-title="$t('INBOX_MGMT.CSAT.DISPLAY_TYPE.DESCRIPTION')"
      >
        <CSATDisplayTypeSelector
          :selected-type="state.displayType"
          @update="updateDisplayType"
        />
      </SettingsSection>

      <SettingsSection
        :title="$t('INBOX_MGMT.CSAT.MESSAGE.LABEL')"
        :sub-title="$t('INBOX_MGMT.CSAT.MESSAGE.DESCRIPTION')"
      >
        <Editor
          v-model="state.message"
          :placeholder="$t('INBOX_MGMT.CSAT.MESSAGE.PLACEHOLDER')"
          :max-length="2000"
        />
      </SettingsSection>

      <SettingsSection
        :title="$t('INBOX_MGMT.CSAT.SURVEY_RULE.LABEL')"
        :sub-title="$t('INBOX_MGMT.CSAT.SURVEY_RULE.DESCRIPTION')"
      >
        <div class="mb-4">
          <span
            class="inline-flex flex-wrap items-center gap-1.5 text-base text-n-slate-12"
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
              hide-label
              variant="faded"
              class="inline-flex shrink-0"
              @update:model-value="handleLabelSelect"
            />
          </span>
        </div>
      </SettingsSection>
    </div>

    <SettingsSection :show-border="false">
      <NextButton
        type="submit"
        :label="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
        :is-loading="isUpdating"
        @click="saveSettings"
      />
    </SettingsSection>
  </div>
</template>
