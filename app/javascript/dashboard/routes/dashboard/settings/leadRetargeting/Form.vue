<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useEligibleConversationsPreview } from 'dashboard/composables/useEligibleConversationsPreview';
import leadFollowUpSequencesAPI from 'dashboard/api/leadFollowUpSequences';
import Button from 'dashboard/components-next/button/Button.vue';
import Modal from 'dashboard/components/Modal.vue';
import SettingIntroBanner from 'dashboard/components/widgets/SettingIntroBanner.vue';
import SettingsSection from 'dashboard/components/SettingsSection.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';

const { t } = useI18n();
const router = useRouter();
const route = useRoute();
const store = useStore();
const getters = useStoreGetters();

const accountId = computed(() => getters.getCurrentAccountId.value);
const inboxes = computed(() =>
  getters['inboxes/getWhatsAppInboxes'].value
);
const agents = computed(() => getters['agents/getAgents'].value);
const teams = computed(() => getters['teams/getTeams'].value);
const labels = computed(() => getters['labels/getLabels'].value);
const pipelineStatuses = computed(() => getters['pipelineStatuses/getPipelineStatuses'].value);

// Transform data for TagMultiSelectComboBox
const labelOptions = computed(() =>
  labels.value.map(label => ({
    value: label.title,
    label: label.title,
  }))
);

const statusOptions = computed(() => [
  {
    label: t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.open.TEXT'),
    value: 'open',
  },
  {
    label: t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.resolved.TEXT'),
    value: 'resolved',
  },
  {
    label: t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.pending.TEXT'),
    value: 'pending',
  },
  {
    label: t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.snoozed.TEXT'),
    value: 'snoozed',
  },
]);

const pipelineStatusOptions = computed(() =>
  pipelineStatuses.value.map(status => ({
    value: status.id,
    label: status.name,
  }))
);

const loading = ref(false);
const availableTemplates = ref([]);

const {
  loading: previewLoading,
  totalCount: eligibleCount,
  conversations: eligibleConversations,
  fetchPreview,
} = useEligibleConversationsPreview();

const showPreviewModal = ref(false);

const defaultSequence = {
  name: '',
  description: '',
  inbox_id: null,
  active: false,
  steps: [],
  trigger_conditions: {
    date_filter: {
      enabled: false,
      filter_type: 'conversation_created_at',
      operator: 'older_than',
      value: 30,
      from_date: null,
      to_date: null,
    },
    label_filter: {
      enabled: false,
      labels: [],
      match_type: 'any',
    },
    status_filter: {
      enabled: false,
      statuses: [],
    },
    pipeline_status_filter: {
      enabled: false,
      pipeline_status_ids: [],
    },
  },
  settings: {
    stop_on_contact_reply: true,
    stop_on_conversation_resolved: true,
    respect_business_hours: false,
    business_hours: {
      start: '09:00',
      end: '18:00',
      timezone: 'America/Mexico_City',
    },
    max_retries_per_step: 2,
  },
};

const sequence = ref(JSON.parse(JSON.stringify(defaultSequence)));

const isEdit = computed(() => !!route.params.sequenceId);
const pageTitle = computed(() =>
  isEdit.value
    ? `${t('LEAD_RETARGETING.FORM.EDIT_TITLE')}: ${sequence.value.name}`
    : t('LEAD_RETARGETING.FORM.NEW_TITLE')
);

const goBack = () => {
  router.push({ name: 'copilots_list' });
};

onMounted(async () => {
  await Promise.all([
    store.dispatch('inboxes/get'),
    store.dispatch('agents/get'),
    store.dispatch('teams/get'),
    store.dispatch('labels/get'),
    store.dispatch('pipelineStatuses/get'),
  ]);

  if (isEdit.value) {
    await fetchSequence();
  }
});

const fetchSequence = async () => {
  try {
    loading.value = true;
    const response = await leadFollowUpSequencesAPI.show(
      route.params.sequenceId
    );
    const data = response.data;
    // Ensure nested objects exist by merging with defaults
    sequence.value = {
      ...defaultSequence,
      ...data,
      trigger_conditions: {
        ...defaultSequence.trigger_conditions,
        ...(data.trigger_conditions || {}),
        date_filter: {
          ...defaultSequence.trigger_conditions.date_filter,
          ...(data.trigger_conditions?.date_filter || {}),
        },
        label_filter: {
          ...defaultSequence.trigger_conditions.label_filter,
          ...(data.trigger_conditions?.label_filter || {}),
        },
        status_filter: {
          ...defaultSequence.trigger_conditions.status_filter,
          ...(data.trigger_conditions?.status_filter || {}),
        },
        pipeline_status_filter: {
          ...defaultSequence.trigger_conditions.pipeline_status_filter,
          ...(data.trigger_conditions?.pipeline_status_filter || {}),
        },
      },
      settings: {
        ...defaultSequence.settings,
        ...(data.settings || {}),
      },
    };
    if (sequence.value.inbox_id) {
      await loadTemplates();
      // Trigger preview after loading sequence
      fetchPreview({
        inbox_id: sequence.value.inbox_id,
        sequence_id: route.params.sequenceId,
        trigger_conditions: sequence.value.trigger_conditions,
        settings: { stop_on_contact_reply: sequence.value.settings.stop_on_contact_reply },
      });
    }
  } catch (error) {
    useAlert(t('LEAD_RETARGETING.FORM.LOAD_ERROR'));
  } finally {
    loading.value = false;
  }
};

const onInboxChange = async () => {
  if (sequence.value.inbox_id) {
    await loadTemplates();
    fetchPreview({
      inbox_id: sequence.value.inbox_id,
      sequence_id: isEdit.value ? route.params.sequenceId : null,
      trigger_conditions: sequence.value.trigger_conditions,
      settings: { stop_on_contact_reply: sequence.value.settings.stop_on_contact_reply },
    });
  } else {
    availableTemplates.value = [];
    eligibleCount.value = null;
    eligibleConversations.value = [];
  }
};

const loadTemplates = async () => {
  if (!sequence.value.inbox_id) return;

  try {
    const response = await leadFollowUpSequencesAPI.getAvailableTemplates(
      sequence.value.inbox_id
    );
    availableTemplates.value = response.data.templates;
  } catch (error) {
    console.error('Failed to load templates:', error);
  }
};

watch(() => sequence.value.inbox_id, loadTemplates);

// Reset filter values when disabled
watch(() => sequence.value.trigger_conditions.date_filter.enabled, (enabled) => {
  if (!enabled) {
    sequence.value.trigger_conditions.date_filter = {
      ...defaultSequence.trigger_conditions.date_filter,
      enabled: false,
    };
  }
});

watch(() => sequence.value.trigger_conditions.label_filter.enabled, (enabled) => {
  if (!enabled) {
    sequence.value.trigger_conditions.label_filter = {
      ...defaultSequence.trigger_conditions.label_filter,
      enabled: false,
    };
  }
});

watch(() => sequence.value.trigger_conditions.status_filter.enabled, (enabled) => {
  if (!enabled) {
    sequence.value.trigger_conditions.status_filter = {
      ...defaultSequence.trigger_conditions.status_filter,
      enabled: false,
    };
  }
});

watch(() => sequence.value.trigger_conditions.pipeline_status_filter.enabled, (enabled) => {
  if (!enabled) {
    sequence.value.trigger_conditions.pipeline_status_filter = {
      ...defaultSequence.trigger_conditions.pipeline_status_filter,
      enabled: false,
    };
  }
});

watch(
  () => ({
    inbox_id: sequence.value.inbox_id,
    sequence_id: isEdit.value ? route.params.sequenceId : null,
    trigger_conditions: sequence.value.trigger_conditions,
    settings: { stop_on_contact_reply: sequence.value.settings.stop_on_contact_reply },
  }),
  (params) => {
    if (params.inbox_id) {
      fetchPreview(params);
    }
  },
  { deep: true, immediate: true }
);

// Watch for route changes to reset form when navigating from edit to create
watch(
  () => route.params.sequenceId,
  async (newSequenceId, oldSequenceId) => {
    // Only reset when navigating FROM edit TO create
    if (oldSequenceId && !newSequenceId) {
      sequence.value = JSON.parse(JSON.stringify(defaultSequence));
      eligibleCount.value = null;
      eligibleConversations.value = [];
      availableTemplates.value = [];
    }
    // When navigating between different edits or from create to edit, fetch the sequence
    else if (newSequenceId && oldSequenceId !== newSequenceId) {
      await fetchSequence();
    }
  }
);

const addStep = type => {
  const stepId = `step_${Date.now()}`;

  const stepDefaults = {
    wait: {
      id: stepId,
      type: 'wait',
      name: t('LEAD_RETARGETING.STEPS.WAIT.DEFAULT_NAME'),
      enabled: true,
      config: {
        delay_type: 'hours',
        delay_value: 24,
      },
    },
    send_template: {
      id: stepId,
      type: 'send_template',
      name: t('LEAD_RETARGETING.STEPS.SEND_TEMPLATE.DEFAULT_NAME'),
      enabled: true,
      config: {
        template_name: '',
        language: 'es',
        template_params: {
          body: {},
        },
      },
    },
    add_label: {
      id: stepId,
      type: 'add_label',
      name: t('LEAD_RETARGETING.STEPS.ADD_LABEL.DEFAULT_NAME'),
      enabled: true,
      config: {
        labels: [],
      },
    },
    remove_label: {
      id: stepId,
      type: 'remove_label',
      name: t('LEAD_RETARGETING.STEPS.REMOVE_LABEL.DEFAULT_NAME'),
      enabled: true,
      config: {
        labels: [],
      },
    },
    assign_agent: {
      id: stepId,
      type: 'assign_agent',
      name: t('LEAD_RETARGETING.STEPS.ASSIGN_AGENT.DEFAULT_NAME'),
      enabled: true,
      config: {
        assignment_type: 'round_robin',
        agent_id: null,
      },
    },
    assign_team: {
      id: stepId,
      type: 'assign_team',
      name: t('LEAD_RETARGETING.STEPS.ASSIGN_TEAM.DEFAULT_NAME'),
      enabled: true,
      config: {
        team_id: null,
      },
    },
    change_priority: {
      id: stepId,
      type: 'change_priority',
      name: t('LEAD_RETARGETING.STEPS.CHANGE_PRIORITY.DEFAULT_NAME'),
      enabled: true,
      config: {
        priority: 'medium',
      },
    },
    update_pipeline_status: {
      id: stepId,
      type: 'update_pipeline_status',
      name: t('LEAD_RETARGETING.STEPS.UPDATE_PIPELINE_STATUS.DEFAULT_NAME'),
      enabled: true,
      config: {
        pipeline_status_id: null,
      },
    },
    webhook: {
      id: stepId,
      type: 'webhook',
      name: t('LEAD_RETARGETING.STEPS.WEBHOOK.DEFAULT_NAME'),
      enabled: true,
      config: {
        url: '',
        method: 'POST',
        headers: {},
        payload: {},
      },
    },
  };

  sequence.value.steps.push(stepDefaults[type]);
};

const removeStep = index => {
  sequence.value.steps.splice(index, 1);
};

const moveStepUp = index => {
  if (index === 0) return;
  const steps = [...sequence.value.steps];
  [steps[index - 1], steps[index]] = [steps[index], steps[index - 1]];
  sequence.value.steps = steps;
};

const moveStepDown = index => {
  if (index === sequence.value.steps.length - 1) return;
  const steps = [...sequence.value.steps];
  [steps[index], steps[index + 1]] = [steps[index + 1], steps[index]];
  sequence.value.steps = steps;
};

const getTemplateParams = templateName => {
  const template = availableTemplates.value.find(t => t.name === templateName);
  if (!template) return [];

  const bodyComponent = template.components?.find(c => c.type === 'BODY');
  if (!bodyComponent || !bodyComponent.text) return [];

  const matches = bodyComponent.text.match(/\{\{(\d+)\}\}/g);
  return matches || [];
};

const onTemplateChange = step => {
  if (!step.config.template_params) {
    step.config.template_params = { body: {} };
  }

  const selectedTemplate = availableTemplates.value.find(t => t.name === step.config.template_name);
  if (selectedTemplate) {
    step.config.language = selectedTemplate.language;
  }

  const params = getTemplateParams(step.config.template_name);
  const bodyParams = {};

  params.forEach((_, idx) => {
    bodyParams[idx + 1] = step.config.template_params.body?.[idx + 1] || '';
  });

  step.config.template_params.body = bodyParams;
};

const copyToClipboard = text => {
  navigator.clipboard.writeText(text);
  useAlert('Variable copiada al portapapeles');
};

const getTemplatePreview = (step) => {
  if (!step.config.template_name) return '';

  const template = availableTemplates.value.find(t => t.name === step.config.template_name);
  if (!template) return '';

  const bodyComponent = template.components?.find(c => c.type === 'BODY');
  if (!bodyComponent || !bodyComponent.text) return '';

  let previewText = bodyComponent.text;

  // Replace {{1}}, {{2}}, etc. with actual values from inputs
  const params = step.config.template_params?.body || {};
  Object.keys(params).forEach(key => {
    const value = params[key] || `{{${key}}}`;
    previewText = previewText.replace(new RegExp(`\\{\\{${key}\\}\\}`, 'g'), value);
  });

  return previewText;
};

const getTemplateCategory = (templateName) => {
  const template = availableTemplates.value.find(t => t.name === templateName);
  return template?.category || '';
};

const getCategoryLabel = (category) => {
  const labels = {
    'UTILITY': 'Utilidad',
    'MARKETING': 'Marketing',
    'AUTHENTICATION': 'Autenticación'
  };
  return labels[category] || category;
};

const getCategoryColor = (category) => {
  const colors = {
    'UTILITY': 'bg-n-blue-3 text-n-blue-11',
    'MARKETING': 'bg-n-iris-3 text-n-iris-11',
    'AUTHENTICATION': 'bg-n-teal-3 text-n-teal-11'
  };
  return colors[category] || 'bg-n-slate-3 text-n-slate-11';
};

const saveSequence = async () => {
  if (!sequence.value.name) {
    useAlert(t('LEAD_RETARGETING.FORM.NAME_REQUIRED'));
    return;
  }

  if (!sequence.value.inbox_id) {
    useAlert(t('LEAD_RETARGETING.FORM.INBOX_REQUIRED'));
    return;
  }

  // Validar filtro de fechas
  const dateFilter = sequence.value.trigger_conditions.date_filter;
  if (dateFilter.enabled) {
    if (dateFilter.operator === 'between') {
      if (!dateFilter.from_date || !dateFilter.to_date) {
        useAlert(t('LEAD_RETARGETING.FORM.DATE_RANGE_REQUIRED'));
        return;
      }
    } else {
      if (!dateFilter.value || dateFilter.value <= 0) {
        useAlert(t('LEAD_RETARGETING.FORM.DATE_VALUE_REQUIRED'));
        return;
      }
    }
  }

  // Validar filtro de etiquetas
  const labelFilter = sequence.value.trigger_conditions.label_filter;
  if (labelFilter.enabled && labelFilter.labels.length === 0) {
    useAlert(t('LEAD_RETARGETING.FORM.LABELS_REQUIRED'));
    return;
  }

  // Validar filtro de status
  const statusFilter = sequence.value.trigger_conditions.status_filter;
  if (statusFilter.enabled && statusFilter.statuses.length === 0) {
    useAlert(t('LEAD_RETARGETING.FORM.STATUSES_REQUIRED'));
    return;
  }

  // Validar filtro de pipeline status
  const pipelineStatusFilter = sequence.value.trigger_conditions.pipeline_status_filter;
  if (pipelineStatusFilter.enabled && pipelineStatusFilter.pipeline_status_ids.length === 0) {
    useAlert(t('LEAD_RETARGETING.FORM.PIPELINE_STATUSES_REQUIRED'));
    return;
  }

  try {
    loading.value = true;

    if (isEdit.value) {
      await leadFollowUpSequencesAPI.update(route.params.sequenceId, {
        lead_follow_up_sequence: sequence.value,
      });
      useAlert(t('LEAD_RETARGETING.FORM.UPDATE_SUCCESS'));
    } else {
      await leadFollowUpSequencesAPI.create({
        lead_follow_up_sequence: sequence.value,
      });
      useAlert(t('LEAD_RETARGETING.FORM.CREATE_SUCCESS'));
    }

    router.push({ name: 'copilots_list' });
  } catch (error) {
    useAlert(
      isEdit.value
        ? t('LEAD_RETARGETING.FORM.UPDATE_ERROR')
        : t('LEAD_RETARGETING.FORM.CREATE_ERROR')
    );
  } finally {
    loading.value = false;
  }
};
</script>

<template>
  <div class="overflow-auto flex-grow flex-shrink pr-0 pl-0 w-full min-w-0 settings">
    <SettingIntroBanner :header-title="pageTitle">
      <button
        class="flex items-center gap-1 text-n-slate-11 hover:text-n-slate-12 text-sm mb-4"
        @click="goBack"
      >
        <i class="i-lucide-arrow-left text-base" />
        {{ t('LEAD_RETARGETING.BREADCRUMB.BACK') }}
      </button>
    </SettingIntroBanner>

    <section class="mx-auto w-full max-w-6xl">
      <div class="mx-8">
        <!-- Basic Information -->
        <SettingsSection
          :title="t('LEAD_RETARGETING.FORM.BASIC_INFO')"
          :sub-title="t('LEAD_RETARGETING.FORM.BASIC_INFO_SUBTITLE')"
        >
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
                {{ t('LEAD_RETARGETING.FORM.NAME') }}
                <span class="text-n-red-10">*</span>
              </label>
              <input
                v-model="sequence.name"
                type="text"
                class="w-full"
                :placeholder="t('LEAD_RETARGETING.FORM.NAME_PLACEHOLDER')"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
                {{ t('LEAD_RETARGETING.FORM.DESCRIPTION') }}
              </label>
              <textarea
                v-model="sequence.description"
                rows="3"
                class="w-full"
                :placeholder="t('LEAD_RETARGETING.FORM.DESCRIPTION_PLACEHOLDER')"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
                {{ t('LEAD_RETARGETING.FORM.INBOX') }}
                <span class="text-n-red-10">*</span>
              </label>
              <select v-model="sequence.inbox_id" class="w-full" @change="onInboxChange">
                <option :value="null">
                  {{ t('LEAD_RETARGETING.FORM.SELECT_INBOX') }}
                </option>
                <option
                  v-for="inbox in inboxes"
                  :key="inbox.id"
                  :value="inbox.id"
                >
                  {{ inbox.name }}
                </option>
              </select>
            </div>
          </div>
        </SettingsSection>

        <!-- Settings -->
        <SettingsSection
          :title="t('LEAD_RETARGETING.FORM.SETTINGS')"
          :sub-title="t('LEAD_RETARGETING.FORM.SETTINGS_SUBTITLE')"
        >
          <div class="space-y-3">
            <label class="flex items-center gap-2 cursor-pointer">
              <input
                v-model="sequence.settings.stop_on_contact_reply"
                type="checkbox"
                class="rounded"
              />
              <span class="text-sm text-n-slate-11">
                {{ t('LEAD_RETARGETING.FORM.STOP_ON_REPLY') }}
              </span>
            </label>

            <label class="flex items-center gap-2 cursor-pointer">
              <input
                v-model="sequence.settings.stop_on_conversation_resolved"
                type="checkbox"
                class="rounded"
              />
              <span class="text-sm text-n-slate-11">
                {{ t('LEAD_RETARGETING.FORM.STOP_ON_RESOLVED') }}
              </span>
            </label>

            <label class="flex items-center gap-2 cursor-pointer">
              <input
                v-model="sequence.active"
                type="checkbox"
                class="rounded"
              />
              <span class="text-sm font-medium text-n-slate-12">
                {{ t('LEAD_RETARGETING.FORM.ACTIVATE') }}
              </span>
            </label>
          </div>
        </SettingsSection>

        <!-- Reactivation Filters -->
        <SettingsSection
          :title="t('LEAD_RETARGETING.FORM.REACTIVATION_FILTERS')"
          :sub-title="t('LEAD_RETARGETING.FORM.REACTIVATION_FILTERS_SUBTITLE')"
        >
          <div class="space-y-6">
            <!-- Date Filter -->
            <div class="border border-n-weak/60 rounded-lg p-4">
              <label class="flex items-center gap-2 cursor-pointer mb-4">
                <input
                  v-model="sequence.trigger_conditions.date_filter.enabled"
                  type="checkbox"
                  class="rounded"
                />
                <span class="text-sm font-medium text-n-slate-12">
                  {{ t('LEAD_RETARGETING.FORM.ENABLE_DATE_FILTER') }}
                </span>
              </label>

              <div v-if="sequence.trigger_conditions.date_filter.enabled" class="space-y-3 pl-6">
                <!-- Filter Type Select -->
                <div>
                  <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
                    {{ t('LEAD_RETARGETING.FORM.DATE_FILTER_TYPE') }}
                  </label>
                  <select v-model="sequence.trigger_conditions.date_filter.filter_type" class="w-full">
                    <option value="conversation_created_at">{{ t('LEAD_RETARGETING.FORM.DATE_FILTER_CONVERSATION_CREATED') }}</option>
                    <option value="last_message_at">{{ t('LEAD_RETARGETING.FORM.DATE_FILTER_LAST_MESSAGE') }}</option>
                    <option value="inactive_days">{{ t('LEAD_RETARGETING.FORM.DATE_FILTER_INACTIVE_DAYS') }}</option>
                  </select>
                </div>

                <!-- Operator Select -->
                <div>
                  <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
                    {{ t('LEAD_RETARGETING.FORM.DATE_OPERATOR') }}
                  </label>
                  <select v-model="sequence.trigger_conditions.date_filter.operator" class="w-full">
                    <option value="older_than">{{ t('LEAD_RETARGETING.FORM.DATE_OPERATOR_OLDER_THAN') }}</option>
                    <option value="newer_than">{{ t('LEAD_RETARGETING.FORM.DATE_OPERATOR_NEWER_THAN') }}</option>
                    <option value="between">{{ t('LEAD_RETARGETING.FORM.DATE_OPERATOR_BETWEEN') }}</option>
                  </select>
                </div>

                <!-- Days Input (for relative operators) -->
                <div v-if="sequence.trigger_conditions.date_filter.operator !== 'between'" class="flex gap-2 items-center">
                  <input
                    v-model.number="sequence.trigger_conditions.date_filter.value"
                    type="number"
                    min="1"
                    class="w-32 px-3 py-2"
                    :placeholder="t('LEAD_RETARGETING.FORM.DAYS')"
                  />
                  <span class="text-sm text-n-slate-11">{{ t('LEAD_RETARGETING.FORM.DAYS') }}</span>
                </div>

                <!-- Date Range (for between operator) -->
                <div v-if="sequence.trigger_conditions.date_filter.operator === 'between'" class="grid grid-cols-2 gap-3">
                  <div>
                    <label class="block text-xs font-medium text-n-slate-12 mb-1">
                      {{ t('LEAD_RETARGETING.FORM.FROM_DATE') }}
                    </label>
                    <input v-model="sequence.trigger_conditions.date_filter.from_date" type="date" class="w-full" />
                  </div>
                  <div>
                    <label class="block text-xs font-medium text-n-slate-12 mb-1">
                      {{ t('LEAD_RETARGETING.FORM.TO_DATE') }}
                    </label>
                    <input v-model="sequence.trigger_conditions.date_filter.to_date" type="date" class="w-full" />
                  </div>
                </div>

                <!-- Help Text -->
                <div class="text-xs text-n-slate-11 bg-n-blue-2 dark:bg-n-blue-3 p-3 rounded">
                  {{ t('LEAD_RETARGETING.FORM.DATE_FILTER_HELP') }}
                </div>
              </div>
            </div>

            <!-- Label Filter -->
            <div class="border border-n-weak/60 rounded-lg p-4">
              <label class="flex items-center gap-2 cursor-pointer mb-4">
                <input
                  v-model="sequence.trigger_conditions.label_filter.enabled"
                  type="checkbox"
                  class="rounded"
                />
                <span class="text-sm font-medium text-n-slate-12">
                  {{ t('LEAD_RETARGETING.FORM.ENABLE_LABEL_FILTER') }}
                </span>
              </label>

              <div v-if="sequence.trigger_conditions.label_filter.enabled" class="space-y-3 pl-6">
                <div>
                  <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
                    {{ t('LEAD_RETARGETING.FORM.SELECT_LABELS') }}
                  </label>
                  <TagMultiSelectComboBox
                    v-model="sequence.trigger_conditions.label_filter.labels"
                    :options="labelOptions"
                    :placeholder="t('LEAD_RETARGETING.FORM.SELECT_LABELS')"
                    :search-placeholder="t('LEAD_RETARGETING.FORM.SEARCH_LABELS')"
                    :empty-state="t('LEAD_RETARGETING.FORM.NO_LABELS_FOUND')"
                  />
                </div>

                <!-- Help Text -->
                <div class="text-xs text-n-slate-11 bg-n-blue-2 dark:bg-n-blue-3 p-3 rounded">
                  {{ t('LEAD_RETARGETING.FORM.LABEL_FILTER_HELP') }}
                </div>
              </div>
            </div>

            <!-- Status Filter -->
            <div class="border border-n-weak/60 rounded-lg p-4">
              <label class="flex items-center gap-2 cursor-pointer mb-4">
                <input
                  v-model="sequence.trigger_conditions.status_filter.enabled"
                  type="checkbox"
                  class="rounded"
                />
                <span class="text-sm font-medium text-n-slate-12">
                  {{ t('LEAD_RETARGETING.FORM.ENABLE_STATUS_FILTER') }}
                </span>
              </label>

              <div v-if="sequence.trigger_conditions.status_filter.enabled" class="space-y-3 pl-6">
                <div>
                  <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
                    {{ t('LEAD_RETARGETING.FORM.SELECT_STATUSES') }}
                  </label>
                  <TagMultiSelectComboBox
                    v-model="sequence.trigger_conditions.status_filter.statuses"
                    :options="statusOptions"
                    :placeholder="t('LEAD_RETARGETING.FORM.SELECT_STATUSES')"
                    :search-placeholder="t('LEAD_RETARGETING.FORM.SEARCH_STATUSES')"
                    :empty-state="t('LEAD_RETARGETING.FORM.NO_STATUSES_FOUND')"
                  />
                </div>

                <!-- Help Text -->
                <div class="text-xs text-n-slate-11 bg-n-blue-2 dark:bg-n-blue-3 p-3 rounded">
                  {{ t('LEAD_RETARGETING.FORM.STATUS_FILTER_HELP') }}
                </div>
              </div>
            </div>

            <!-- Pipeline Status Filter -->
            <div class="border border-n-weak/60 rounded-lg p-4">
              <label class="flex items-center gap-2 cursor-pointer mb-4">
                <input
                  v-model="sequence.trigger_conditions.pipeline_status_filter.enabled"
                  type="checkbox"
                  class="rounded"
                />
                <span class="text-sm font-medium text-n-slate-12">
                  {{ t('LEAD_RETARGETING.FORM.ENABLE_PIPELINE_STATUS_FILTER') }}
                </span>
              </label>

              <div v-if="sequence.trigger_conditions.pipeline_status_filter.enabled" class="space-y-3 pl-6">
                <div>
                  <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
                    {{ t('LEAD_RETARGETING.FORM.SELECT_PIPELINE_STATUSES') }}
                  </label>
                  <TagMultiSelectComboBox
                    v-model="sequence.trigger_conditions.pipeline_status_filter.pipeline_status_ids"
                    :options="pipelineStatusOptions"
                    :placeholder="t('LEAD_RETARGETING.FORM.SELECT_PIPELINE_STATUSES')"
                    :search-placeholder="t('LEAD_RETARGETING.FORM.SEARCH_PIPELINE_STATUSES')"
                    :empty-state="t('LEAD_RETARGETING.FORM.NO_PIPELINE_STATUSES_FOUND')"
                  />
                </div>

                <!-- Help Text -->
                <div class="text-xs text-n-slate-11 bg-n-blue-2 dark:bg-n-blue-3 p-3 rounded">
                  {{ t('LEAD_RETARGETING.FORM.PIPELINE_STATUS_FILTER_HELP') }}
                </div>
              </div>
            </div>
          </div>

          <!-- Eligible Conversations Preview -->
          <div v-if="sequence.inbox_id" class="mt-6 p-4 bg-n-blue-2 dark:bg-n-blue-3 rounded-lg border border-n-blue-6">
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-3">
                <i class="i-lucide-filter text-xl text-n-blue-11" />
                <div>
                  <p class="text-sm font-medium text-n-slate-12">
                    Conversaciones Elegibles
                  </p>
                  <p class="text-xs text-n-slate-11">
                    Basado en los filtros configurados
                  </p>
                </div>
              </div>

              <div class="flex items-center gap-3">
                <!-- Loading Spinner -->
                <div v-if="previewLoading" class="flex items-center gap-2">
                  <i class="i-lucide-loader-2 animate-spin text-n-blue-11" />
                  <span class="text-sm text-n-slate-11">Calculando...</span>
                </div>

                <!-- Count Badge -->
                <div v-else-if="eligibleCount !== null" class="flex items-center gap-2">
                  <span class="px-3 py-1.5 bg-n-blue-9 text-white font-semibold rounded-full text-lg">
                    {{ eligibleCount.toLocaleString() }}
                  </span>
                  <span class="text-sm text-n-slate-11">conversaciones</span>

                  <!-- View Details Button -->
                  <Button
                    xs
                    blue
                    faded
                    label="Ver Detalles"
                    icon="i-lucide-list"
                    @click="showPreviewModal = true"
                  />
                </div>
              </div>
            </div>
          </div>
        </SettingsSection>

        <!-- Sequence Steps -->
        <SettingsSection
          :title="t('LEAD_RETARGETING.FORM.STEPS')"
          :sub-title="t('LEAD_RETARGETING.FORM.STEPS_SUBTITLE')"
        >
          <div class="space-y-4">
            <!-- Add Step Buttons -->
            <div class="flex gap-2 flex-wrap">
              <Button
                xs
                slate
                faded
                :label="'+ ' + t('LEAD_RETARGETING.STEPS.WAIT.ADD')"
                @click="addStep('wait')"
              />
              <Button
                xs
                slate
                faded
                :label="'+ ' + t('LEAD_RETARGETING.STEPS.SEND_TEMPLATE.ADD')"
                :disabled="!sequence.inbox_id"
                @click="addStep('send_template')"
              />
              <Button
                xs
                slate
                faded
                :label="'+ ' + t('LEAD_RETARGETING.STEPS.ADD_LABEL.ADD')"
                @click="addStep('add_label')"
              />
              <Button
                xs
                slate
                faded
                :label="'+ ' + t('LEAD_RETARGETING.STEPS.REMOVE_LABEL.ADD')"
                @click="addStep('remove_label')"
              />
              <Button
                xs
                slate
                faded
                :label="'+ ' + t('LEAD_RETARGETING.STEPS.ASSIGN_AGENT.ADD')"
                @click="addStep('assign_agent')"
              />
              <Button
                xs
                slate
                faded
                :label="'+ ' + t('LEAD_RETARGETING.STEPS.ASSIGN_TEAM.ADD')"
                @click="addStep('assign_team')"
              />
              <Button
                xs
                slate
                faded
                :label="'+ ' + t('LEAD_RETARGETING.STEPS.CHANGE_PRIORITY.ADD')"
                @click="addStep('change_priority')"
              />
              <Button
                xs
                slate
                faded
                :label="'+ ' + t('LEAD_RETARGETING.STEPS.UPDATE_PIPELINE_STATUS.ADD')"
                @click="addStep('update_pipeline_status')"
              />
              <Button
                xs
                slate
                faded
                :label="'+ ' + t('LEAD_RETARGETING.STEPS.WEBHOOK.ADD')"
                @click="addStep('webhook')"
              />
            </div>

            <!-- No Steps Message -->
            <div v-if="sequence.steps.length === 0" class="text-center py-8 text-n-slate-11">
              {{ t('LEAD_RETARGETING.FORM.NO_STEPS') }}
            </div>

            <!-- Steps List -->
            <div v-else class="space-y-3">
              <div
                v-for="(step, index) in sequence.steps"
                :key="step.id"
                class="border border-n-weak/60 rounded-lg p-4"
              >
                <div class="flex items-start gap-4">
                  <!-- Order Controls -->
                  <div class="flex flex-col gap-1">
                    <button
                      type="button"
                      :disabled="index === 0"
                      class="text-n-slate-11 hover:text-n-slate-12 disabled:opacity-30 disabled:cursor-not-allowed"
                      @click="moveStepUp(index)"
                    >
                      <i class="i-lucide-chevron-up text-base" />
                    </button>
                    <span class="text-sm font-medium text-n-slate-11">{{ index + 1 }}</span>
                    <button
                      type="button"
                      :disabled="index === sequence.steps.length - 1"
                      class="text-n-slate-11 hover:text-n-slate-12 disabled:opacity-30 disabled:cursor-not-allowed"
                      @click="moveStepDown(index)"
                    >
                      <i class="i-lucide-chevron-down text-base" />
                    </button>
                  </div>

                  <!-- Step Content -->
                  <div class="flex-1">
                    <input
                      v-model="step.name"
                      type="text"
                      class="w-full mb-3"
                      :placeholder="t('LEAD_RETARGETING.FORM.STEP_NAME')"
                    />

                    <!-- Wait Step -->
                    <div v-if="step.type === 'wait'" class="flex gap-2 items-center">
                      <span class="text-sm text-n-slate-11">{{ t('LEAD_RETARGETING.STEPS.WAIT.LABEL') }}</span>
                      <input
                        v-model.number="step.config.delay_value"
                        type="number"
                        min="1"
                        class="w-20 px-2 py-1"
                      />
                      <select v-model="step.config.delay_type" class="px-2 py-1">
                        <option value="minutes">{{ t('LEAD_RETARGETING.STEPS.WAIT.MINUTES') }}</option>
                        <option value="hours">{{ t('LEAD_RETARGETING.STEPS.WAIT.HOURS') }}</option>
                        <option value="days">{{ t('LEAD_RETARGETING.STEPS.WAIT.DAYS') }}</option>
                      </select>
                    </div>

                    <!-- Send Template Step -->
                    <div v-else-if="step.type === 'send_template'" class="space-y-3">
                      <div>
                        <label class="block text-xs font-medium text-n-slate-12 mb-1">Template</label>
                        <select
                          v-model="step.config.template_name"
                          class="w-full text-sm"
                          @change="onTemplateChange(step)"
                        >
                          <option value="">{{ t('LEAD_RETARGETING.STEPS.SEND_TEMPLATE.SELECT') }}</option>
                          <option
                            v-for="template in availableTemplates"
                            :key="`${template.name}-${template.language}`"
                            :value="template.name"
                          >
                            {{ template.name }} ({{ template.language }})
                          </option>
                        </select>
                      </div>

                      <!-- Template Category & Info -->
                      <div v-if="step.config.template_name" class="flex items-center gap-2">
                        <span class="text-xs text-n-slate-11">Categoría:</span>
                        <span
                          class="text-xs px-2 py-1 rounded font-medium"
                          :class="getCategoryColor(getTemplateCategory(step.config.template_name))"
                        >
                          {{ getCategoryLabel(getTemplateCategory(step.config.template_name)) }}
                        </span>
                      </div>

                      <!-- Template Parameters -->
                      <div v-if="step.config.template_name && getTemplateParams(step.config.template_name).length > 0" class="space-y-2 p-3 bg-n-weak/30 rounded">
                        <label class="block text-xs font-medium text-n-slate-12 mb-2">Parámetros del Template</label>
                        <div
                          v-for="(param, idx) in getTemplateParams(step.config.template_name)"
                          :key="idx"
                          class="flex items-center gap-2"
                        >
                          <span class="text-xs text-n-slate-11 w-16">{{ '{' + '{' + (idx + 1) + '}' + '}' }}:</span>
                          <input
                            v-model="step.config.template_params.body[idx + 1]"
                            type="text"
                            class="flex-1 px-2 py-1 text-sm"
                            :placeholder="`Valor para parámetro ${idx + 1}`"
                          />
                        </div>
                        <div class="mt-2 p-2 bg-n-blue-2 dark:bg-n-blue-3 rounded text-xs">
                          <p class="font-medium text-n-slate-12 mb-1">Variables disponibles:</p>
                          <div class="flex flex-wrap gap-2">
                            <code
                              v-for="variable in ['contact.name', 'contact.email', 'contact.phone_number']"
                              :key="variable"
                              class="px-2 py-0.5 bg-white dark:bg-n-slate-3 border border-n-weak/60 rounded cursor-pointer hover:bg-n-blue-4 text-n-slate-12"
                              @click="copyToClipboard(`{{${variable}}}`)"
                            >
                              {{ '{' + '{' + variable + '}' + '}' }}
                            </code>
                          </div>
                        </div>
                      </div>

                      <!-- Message Preview -->
                      <div v-if="step.config.template_name && getTemplatePreview(step)" class="p-3 bg-n-green-2 dark:bg-n-green-3 border border-n-green-6 rounded-lg">
                        <div class="flex items-start gap-2 mb-1">
                          <i class="i-lucide-eye text-n-green-11 text-sm mt-0.5" />
                          <p class="text-xs font-medium text-n-green-11">Vista previa del mensaje</p>
                        </div>
                        <div class="mt-2 p-3 bg-white dark:bg-n-slate-2 rounded border border-n-weak/60">
                          <p class="text-sm text-n-slate-12 whitespace-pre-wrap">{{ getTemplatePreview(step) }}</p>
                        </div>
                      </div>
                    </div>

                    <!-- Add Label Step -->
                    <div v-else-if="step.type === 'add_label'" class="space-y-2">
                      <label class="block text-xs font-medium text-n-slate-12 mb-1">
                        {{ t('LEAD_RETARGETING.STEPS.ADD_LABEL.SELECT_LABEL') }}
                      </label>
                      <select v-model="step.config.labels[0]" class="w-full">
                        <option value="">{{ t('LEAD_RETARGETING.STEPS.ADD_LABEL.PLACEHOLDER') }}</option>
                        <option
                          v-for="label in labels"
                          :key="label.id"
                          :value="label.title"
                        >
                          {{ label.title }}
                        </option>
                      </select>
                    </div>

                    <!-- Remove Label Step -->
                    <div v-else-if="step.type === 'remove_label'" class="space-y-2">
                      <label class="block text-xs font-medium text-n-slate-12 mb-1">
                        {{ t('LEAD_RETARGETING.STEPS.REMOVE_LABEL.SELECT_LABEL') }}
                      </label>
                      <select v-model="step.config.labels[0]" class="w-full">
                        <option value="">{{ t('LEAD_RETARGETING.STEPS.REMOVE_LABEL.PLACEHOLDER') }}</option>
                        <option
                          v-for="label in labels"
                          :key="label.id"
                          :value="label.title"
                        >
                          {{ label.title }}
                        </option>
                      </select>
                    </div>

                    <!-- Assign Agent Step -->
                    <div v-else-if="step.type === 'assign_agent'" class="space-y-2">
                      <div>
                        <label class="block text-xs font-medium text-n-slate-12 mb-1">
                          {{ t('LEAD_RETARGETING.STEPS.ASSIGN_AGENT.TYPE') }}
                        </label>
                        <select v-model="step.config.assignment_type" class="w-full">
                          <option value="round_robin">{{ t('LEAD_RETARGETING.STEPS.ASSIGN_AGENT.ROUND_ROBIN') }}</option>
                          <option value="specific_agent">{{ t('LEAD_RETARGETING.STEPS.ASSIGN_AGENT.SPECIFIC') }}</option>
                        </select>
                      </div>
                      <div v-if="step.config.assignment_type === 'specific_agent'">
                        <label class="block text-xs font-medium text-n-slate-12 mb-1">
                          {{ t('LEAD_RETARGETING.STEPS.ASSIGN_AGENT.SELECT_AGENT') }}
                        </label>
                        <select v-model="step.config.agent_id" class="w-full">
                          <option :value="null">{{ t('LEAD_RETARGETING.STEPS.ASSIGN_AGENT.SELECT_PLACEHOLDER') }}</option>
                          <option
                            v-for="agent in agents"
                            :key="agent.id"
                            :value="agent.id"
                          >
                            {{ agent.name }}
                          </option>
                        </select>
                      </div>
                    </div>

                    <!-- Assign Team Step -->
                    <div v-else-if="step.type === 'assign_team'" class="space-y-2">
                      <label class="block text-xs font-medium text-n-slate-12 mb-1">
                        {{ t('LEAD_RETARGETING.STEPS.ASSIGN_TEAM.SELECT_TEAM') }}
                      </label>
                      <select v-model="step.config.team_id" class="w-full">
                        <option :value="null">{{ t('LEAD_RETARGETING.STEPS.ASSIGN_TEAM.SELECT_PLACEHOLDER') }}</option>
                        <option
                          v-for="team in teams"
                          :key="team.id"
                          :value="team.id"
                        >
                          {{ team.name }}
                        </option>
                      </select>
                    </div>

                    <!-- Change Priority Step -->
                    <div v-else-if="step.type === 'change_priority'" class="space-y-2">
                      <label class="block text-xs font-medium text-n-slate-12 mb-1">
                        {{ t('LEAD_RETARGETING.STEPS.CHANGE_PRIORITY.SELECT_PRIORITY') }}
                      </label>
                      <select v-model="step.config.priority" class="w-full">
                        <option value="low">{{ t('LEAD_RETARGETING.STEPS.CHANGE_PRIORITY.LOW') }}</option>
                        <option value="medium">{{ t('LEAD_RETARGETING.STEPS.CHANGE_PRIORITY.MEDIUM') }}</option>
                        <option value="high">{{ t('LEAD_RETARGETING.STEPS.CHANGE_PRIORITY.HIGH') }}</option>
                        <option value="urgent">{{ t('LEAD_RETARGETING.STEPS.CHANGE_PRIORITY.URGENT') }}</option>
                      </select>
                    </div>

                    <!-- Update Pipeline Status Step -->
                    <div v-else-if="step.type === 'update_pipeline_status'" class="space-y-2">
                      <label class="block text-xs font-medium text-n-slate-12 mb-1">
                        {{ t('LEAD_RETARGETING.STEPS.UPDATE_PIPELINE_STATUS.SELECT_STATUS') }}
                      </label>
                      <select v-model="step.config.pipeline_status_id" class="w-full">
                        <option :value="null">{{ t('LEAD_RETARGETING.STEPS.UPDATE_PIPELINE_STATUS.SELECT_PLACEHOLDER') }}</option>
                        <option
                          v-for="pipelineStatus in pipelineStatuses"
                          :key="pipelineStatus.id"
                          :value="pipelineStatus.id"
                        >
                          {{ pipelineStatus.name }}
                        </option>
                      </select>
                    </div>

                    <!-- Webhook Step -->
                    <div v-else-if="step.type === 'webhook'" class="space-y-2">
                      <div>
                        <label class="block text-xs font-medium text-n-slate-12 mb-1">
                          {{ t('LEAD_RETARGETING.STEPS.WEBHOOK.URL') }}
                        </label>
                        <input
                          v-model="step.config.url"
                          type="url"
                          class="w-full"
                          :placeholder="t('LEAD_RETARGETING.STEPS.WEBHOOK.URL_PLACEHOLDER')"
                        />
                      </div>
                      <div>
                        <label class="block text-xs font-medium text-n-slate-12 mb-1">
                          {{ t('LEAD_RETARGETING.STEPS.WEBHOOK.METHOD') }}
                        </label>
                        <select v-model="step.config.method" class="w-full">
                          <option value="GET">GET</option>
                          <option value="POST">POST</option>
                          <option value="PUT">PUT</option>
                          <option value="PATCH">PATCH</option>
                          <option value="DELETE">DELETE</option>
                        </select>
                      </div>
                      <div class="text-xs text-n-slate-11">
                        {{ t('LEAD_RETARGETING.STEPS.WEBHOOK.VARIABLES_HINT') }}
                      </div>
                    </div>
                  </div>

                  <!-- Delete Button -->
                  <Button
                    v-tooltip.top="t('LEAD_RETARGETING.FORM.DELETE_STEP')"
                    icon="i-lucide-trash-2"
                    xs
                    ruby
                    faded
                    @click="removeStep(index)"
                  />
                </div>
              </div>
            </div>
          </div>
        </SettingsSection>

        <!-- Action Buttons -->
        <SettingsSection :show-border="false">
          <div class="flex gap-2">
            <Button
              slate
              :label="t('LEAD_RETARGETING.FORM.CANCEL')"
              @click="goBack"
            />
            <Button
              :is-loading="loading"
              :label="t('LEAD_RETARGETING.FORM.SAVE')"
              @click="saveSequence"
            />
          </div>
        </SettingsSection>
      </div>
    </section>

    <!-- Eligible Conversations Modal -->
    <Modal
      v-model:show="showPreviewModal"
      :on-close="() => showPreviewModal = false"
    >
      <div class="p-6 w-full max-w-3xl">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-lg font-semibold text-n-slate-12">
            Conversaciones Elegibles
          </h3>
          <span class="text-sm text-n-slate-11">
            Total: {{ eligibleCount?.toLocaleString() }}
          </span>
        </div>

        <!-- Conversations List -->
        <div v-if="eligibleConversations.length > 0" class="space-y-2 max-h-96 overflow-y-auto">
          <div
            v-for="conv in eligibleConversations"
            :key="conv.id"
            class="flex items-center gap-3 p-3 border border-n-weak/60 rounded hover:bg-n-weak/30 transition-colors"
          >
            <div class="flex-1">
              <p class="font-medium text-n-slate-12">
                {{ conv.contact?.name || 'Sin nombre' }}
              </p>
              <p class="text-xs text-n-slate-11">
                {{ conv.contact?.phone_number || 'Sin número' }}
              </p>
            </div>
            <span class="text-xs px-2 py-1 bg-n-weak/60 rounded font-mono">
              #{{ conv.display_id }}
            </span>
            <span
              class="text-xs px-2 py-1 rounded font-medium capitalize"
              :class="{
                'bg-n-green-3 text-n-green-11': conv.status === 'open',
                'bg-n-blue-3 text-n-blue-11': conv.status === 'pending',
                'bg-n-slate-3 text-n-slate-11': conv.status === 'resolved',
                'bg-n-yellow-3 text-n-yellow-11': conv.status === 'snoozed',
              }"
            >
              {{ conv.status }}
            </span>
          </div>
        </div>

        <!-- Empty State -->
        <div v-else class="py-8 text-center text-n-slate-11">
          <i class="i-lucide-inbox text-4xl mb-2" />
          <p>No hay conversaciones para mostrar</p>
        </div>

        <!-- Note -->
        <div class="mt-4 p-3 bg-n-blue-2 dark:bg-n-blue-3 rounded text-xs text-n-slate-11">
          <p>
            Mostrando las primeras {{ eligibleConversations.length }} conversaciones.
            {{ eligibleCount > 20 ? `Hay ${eligibleCount - 20} más que coinciden con los filtros.` : '' }}
          </p>
        </div>
      </div>
    </Modal>
  </div>
</template>
