<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useEligibleConversationsPreview } from 'dashboard/composables/useEligibleConversationsPreview';
import { useNotionDatabase } from 'dashboard/composables/useNotionDatabase';
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
const inboxes = computed(() => getters['inboxes/getWhatsAppInboxes'].value);
const agents = computed(() => getters['agents/getAgents'].value);
const teams = computed(() => getters['teams/getTeams'].value);
const labels = computed(() => getters['labels/getLabels'].value);
const pipelineStatuses = computed(
  () => getters['pipelineStatuses/getPipelineStatuses'].value
);

// Transform data for TagMultiSelectComboBox
const labelOptions = computed(() => {
  if (!labels.value || !Array.isArray(labels.value)) return [];
  return labels.value.map(label => ({
    value: label.title,
    label: label.title,
  }));
});

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

const pipelineStatusOptions = computed(() => {
  if (!pipelineStatuses.value || !Array.isArray(pipelineStatuses.value))
    return [];
  return pipelineStatuses.value.map(status => ({
    value: status.id,
    label: status.name,
  }));
});

const loading = ref(false);
const availableTemplates = ref([]);

const {
  loading: previewLoading,
  totalCount: eligibleCount,
  conversations: eligibleConversations,
  fetchPreview,
} = useEligibleConversationsPreview();

const showPreviewModal = ref(false);
const showNotionPreviewModal = ref(false);

// Notion Database Integration
const {
  databases: notionDatabases,
  databaseSchema,
  notionRecordsPreview,
  loading: notionLoading,
  loadingPreview: notionLoadingPreview,
  textFields: notionTextFields,
  dateFields: notionDateFields,
  phoneNumberFields: notionPhoneFields,
  emailFields: notionEmailFields,
  allFields: notionAllFields,
  fetchDatabases: fetchNotionDatabases,
  fetchDatabaseSchema,
  queryDatabase: queryNotionDatabase,
} = useNotionDatabase();

const customAttributeCounter = ref(0);

const defaultSequence = {
  name: '',
  description: '',
  inbox_id: null,
  active: false,
  source_type: 'existing_conversations', // 'existing_conversations' | 'notion_database'
  source_config: {
    notion_database_id: null,
    notion_database_name: '',
    field_mappings: {
      phone_number: '',
      name: '',
      email: '',
      reference_date: '',
      custom_attributes: {},
    },
    notion_filters: {
      select_filters: [],
      date_filters: [],
      checkbox_filters: [],
    },
  },
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
    enrollment_filter: {
      include_completed: true,
    },
  },
  settings: {
    stop_on_contact_reply: true,
    stop_on_conversation_resolved: true,
    stop_on_agent_assigned: false,
    stop_on_agent_reply: false,
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

// Check if first_contact step exists (for Notion copilots)
const hasFirstContactStep = computed(() => {
  return sequence.value.steps.some(step => step.type === 'first_contact');
});

// Check if first_contact step can be added (only one allowed, must be first)
const canAddFirstContact = computed(() => {
  return (
    sequence.value.source_type === 'notion_database' &&
    !hasFirstContactStep.value
  );
});

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

  // Load Notion databases after sequence if in edit mode (to preserve existing config)
  // Or immediately if creating new
  await loadNotionDatabasesIfNeeded();
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
        enrollment_filter: {
          ...defaultSequence.trigger_conditions.enrollment_filter,
          ...(data.trigger_conditions?.enrollment_filter || {}),
        },
      },
      settings: {
        ...defaultSequence.settings,
        ...(data.settings || {}),
      },
    };

    // Load templates for regular copilots (inbox at sequence level)
    if (sequence.value.inbox_id) {
      await loadTemplates();
      // Trigger preview after loading sequence
      fetchPreview({
        inbox_id: sequence.value.inbox_id,
        sequence_id: route.params.sequenceId,
        trigger_conditions: sequence.value.trigger_conditions,
        settings: {
          stop_on_contact_reply: sequence.value.settings.stop_on_contact_reply,
        },
      });
    }

    // Load templates for Notion copilots (inbox in first_contact step)
    if (sequence.value.source_type === 'notion_database') {
      const firstContactStep = sequence.value.steps?.find(
        s => s.type === 'first_contact'
      );
      if (
        firstContactStep?.config?.channel === 'whatsapp' &&
        firstContactStep?.config?.inbox_id
      ) {
        try {
          const response = await leadFollowUpSequencesAPI.getAvailableTemplates(
            firstContactStep.config.inbox_id
          );
          availableTemplates.value = response.data.templates;
        } catch (error) {
          console.error('Failed to load templates for first_contact step:', error);
        }
      }
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
      settings: {
        stop_on_contact_reply: sequence.value.settings.stop_on_contact_reply,
      },
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
watch(
  () => sequence.value.trigger_conditions.date_filter.enabled,
  enabled => {
    if (!enabled) {
      sequence.value.trigger_conditions.date_filter = {
        ...defaultSequence.trigger_conditions.date_filter,
        enabled: false,
      };
    }
  }
);

watch(
  () => sequence.value.trigger_conditions.label_filter.enabled,
  enabled => {
    if (!enabled) {
      sequence.value.trigger_conditions.label_filter = {
        ...defaultSequence.trigger_conditions.label_filter,
        enabled: false,
      };
    }
  }
);

watch(
  () => sequence.value.trigger_conditions.status_filter.enabled,
  enabled => {
    if (!enabled) {
      sequence.value.trigger_conditions.status_filter = {
        ...defaultSequence.trigger_conditions.status_filter,
        enabled: false,
      };
    }
  }
);

watch(
  () => sequence.value.trigger_conditions.pipeline_status_filter.enabled,
  enabled => {
    if (!enabled) {
      sequence.value.trigger_conditions.pipeline_status_filter = {
        ...defaultSequence.trigger_conditions.pipeline_status_filter,
        enabled: false,
      };
    }
  }
);

watch(
  () => ({
    inbox_id: sequence.value.inbox_id,
    sequence_id: isEdit.value ? route.params.sequenceId : null,
    trigger_conditions: sequence.value.trigger_conditions,
    settings: {
      stop_on_contact_reply: sequence.value.settings.stop_on_contact_reply,
    },
  }),
  params => {
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
    first_contact: {
      id: stepId,
      type: 'first_contact',
      name: 'Primer Contacto desde Notion',
      enabled: true,
      config: {
        channel: 'whatsapp', // 'whatsapp' | 'sms'
        inbox_id: null, // Inbox donde se creará la conversación
        template_name: '',
        language: 'es',
        template_params: {
          body: {},
        },
        sms_context: '', // Contexto para AI (SMS)
      },
    },
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
    send_message: {
      id: stepId,
      type: 'send_message',
      name: t('LEAD_RETARGETING.STEPS.SEND_MESSAGE.DEFAULT_NAME'),
      enabled: true,
      config: {
        ai_config: {
          enabled: true,
          context: '',
          variables: {},
        },
        closed_window_action: 'send_template',
        template_config: {
          template_name: '',
          language: 'es',
          template_params: {
            body: {},
          },
        },
        sms_config: {
          context: '',
          variables: {},
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
    send_email: {
      id: stepId,
      type: 'send_email',
      name: t('LEAD_RETARGETING.STEPS.SEND_EMAIL.DEFAULT_NAME'),
      enabled: true,
      config: {
        subject: '',
        content: '',
        sender_email: '',
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

const onFirstContactChannelChange = async step => {
  // Reset template when changing channel
  step.config.template_name = '';
  step.config.template_params = { body: {} };

  // Load templates if switching to WhatsApp and inbox is already selected
  if (step.config.channel === 'whatsapp' && step.config.inbox_id) {
    await onFirstContactInboxChange(step);
  }
};

const onFirstContactInboxChange = async step => {
  // When inbox changes in first_contact step, load templates if WhatsApp
  if (step.config.channel === 'whatsapp' && step.config.inbox_id) {
    try {
      const response = await leadFollowUpSequencesAPI.getAvailableTemplates(
        step.config.inbox_id
      );
      availableTemplates.value = response.data.templates;
    } catch (error) {
      console.error('Failed to load templates for first contact:', error);
      useAlert('Error al cargar templates de WhatsApp');
    }
  }
};

const getTemplateParams = templateName => {
  const template = availableTemplates.value.find(t => t.name === templateName);
  if (!template) return [];

  const bodyComponent = template.components?.find(c => c.type === 'BODY');
  if (!bodyComponent || !bodyComponent.text) return [];

  const matches = bodyComponent.text.match(/\{\{(\d+)\}\}/g);
  return matches || [];
};

const onTemplateChange = (step, configPath = 'config') => {
  // For send_message steps, configPath will be 'template_config'
  // For send_template steps, configPath will be 'config' (default)
  const config =
    configPath === 'config' ? step.config : step.config[configPath];

  if (!config.template_params) {
    config.template_params = { body: {} };
  }

  const selectedTemplate = availableTemplates.value.find(
    t => t.name === config.template_name
  );
  if (selectedTemplate) {
    config.language = selectedTemplate.language;
  }

  const params = getTemplateParams(config.template_name);
  const bodyParams = {};

  params.forEach((_, idx) => {
    bodyParams[idx + 1] = config.template_params.body?.[idx + 1] || '';
  });

  config.template_params.body = bodyParams;
};

const copyToClipboard = text => {
  navigator.clipboard.writeText(text);
  useAlert('Variable copiada al portapapeles');
};

const getTemplatePreview = (step, configPath = 'config') => {
  // For send_message steps with template_config, configPath will be 'template_config'
  const config =
    configPath === 'config' ? step.config : step.config[configPath];

  if (!config?.template_name) return '';

  const template = availableTemplates.value.find(
    t => t.name === config.template_name
  );
  if (!template) return '';

  const bodyComponent = template.components?.find(c => c.type === 'BODY');
  if (!bodyComponent || !bodyComponent.text) return '';

  let previewText = bodyComponent.text;

  // Replace {{1}}, {{2}}, etc. with actual values from inputs
  const params = config.template_params?.body || {};
  Object.keys(params).forEach(key => {
    const value = params[key] || `{{${key}}}`;
    previewText = previewText.replace(
      new RegExp(`\\{\\{${key}\\}\\}`, 'g'),
      value
    );
  });

  return previewText;
};

const getTemplateCategory = templateName => {
  const template = availableTemplates.value.find(t => t.name === templateName);
  return template?.category || '';
};

const getCategoryLabel = category => {
  const labels = {
    UTILITY: 'Utilidad',
    MARKETING: 'Marketing',
    AUTHENTICATION: 'Autenticación',
  };
  return labels[category] || category;
};

const getCategoryColor = category => {
  const colors = {
    UTILITY: 'bg-n-blue-3 text-n-blue-11',
    MARKETING: 'bg-n-iris-3 text-n-iris-11',
    AUTHENTICATION: 'bg-n-teal-3 text-n-teal-11',
  };
  return colors[category] || 'bg-n-slate-3 text-n-slate-11';
};

// Load Notion databases if integration is active
const loadNotionDatabasesIfNeeded = async () => {
  // Check if Notion integration exists
  const notionIntegration =
    store.getters['integrations/getIntegration']('notion');

  if (!notionIntegration) {
    console.log('Notion integration not found');
    return;
  }

  // Load databases
  try {
    await fetchNotionDatabases();

    // If editing and database is already selected, load its schema
    if (isEdit.value && sequence.value.source_config?.notion_database_id) {
      await fetchDatabaseSchema(
        sequence.value.source_config.notion_database_id
      );
    }
  } catch (error) {
    console.error('Failed to load Notion databases:', error);
    if (error.response?.status === 401) {
      useAlert(
        'Notion no está conectado. Por favor conecta Notion en Integraciones.'
      );
    }
  }
};

// Watch for source_type changes to load Notion data
watch(
  () => sequence.value.source_type,
  async newType => {
    if (newType === 'notion_database' && notionDatabases.value.length === 0) {
      await loadNotionDatabasesIfNeeded();
    }
  }
);

// Notion-specific handlers
const onNotionDatabaseChange = async () => {
  console.log(
    'Database changed:',
    sequence.value.source_config.notion_database_id
  );

  if (!sequence.value.source_config.notion_database_id) {
    databaseSchema.value = null;
    sequence.value.source_config.notion_database_name = '';
    return;
  }

  // Load database schema
  try {
    console.log(
      'Fetching schema for database:',
      sequence.value.source_config.notion_database_id
    );
    const schema = await fetchDatabaseSchema(
      sequence.value.source_config.notion_database_id
    );

    console.log('Schema loaded:', schema);
    console.log('Properties:', schema?.properties);

    if (schema) {
      // Find and set database name
      const selectedDb = notionDatabases.value.find(
        db => db.id === sequence.value.source_config.notion_database_id
      );
      if (selectedDb) {
        sequence.value.source_config.notion_database_name = selectedDb.title;
      }

      // Reset field mappings when database changes (preserve existing if editing same database)
      if (
        !isEdit.value ||
        sequence.value.source_config.field_mappings.phone_number === ''
      ) {
        sequence.value.source_config.field_mappings = {
          phone_number: '',
          name: '',
          email: '',
          reference_date: '',
          custom_attributes: {},
        };
      }

      // Initialize notion_filters structure if it doesn't exist
      if (!sequence.value.source_config.notion_filters) {
        sequence.value.source_config.notion_filters = {
          select_filters: [],
          date_filters: [],
          checkbox_filters: [],
        };
      }

      // Debug computed properties
      console.log('Phone fields:', notionPhoneFields.value);
      console.log('Text fields:', notionTextFields.value);
      console.log('Date fields:', notionDateFields.value);
    }
  } catch (error) {
    console.error('Failed to load database schema:', error);
    useAlert('Error al cargar el schema de la base de datos de Notion');
  }
};

const addCustomAttribute = () => {
  const key = `custom_attr_${Date.now()}`;
  if (!sequence.value.source_config.field_mappings.custom_attributes) {
    sequence.value.source_config.field_mappings.custom_attributes = {};
  }
  sequence.value.source_config.field_mappings.custom_attributes[key] = '';
};

const removeCustomAttribute = key => {
  delete sequence.value.source_config.field_mappings.custom_attributes[key];
};

const renameCustomAttributeKey = (oldKey, newKey) => {
  // Sanitize new key: lowercase, no spaces, alphanumeric and underscore only
  const sanitizedKey = newKey
    .toLowerCase()
    .replace(/\s+/g, '_')
    .replace(/[^a-z0-9_]/g, '');

  if (!sanitizedKey || sanitizedKey === oldKey) return;

  // Check if key already exists
  if (sequence.value.source_config.field_mappings.custom_attributes[sanitizedKey]) {
    useAlert('Ya existe un atributo con ese nombre');
    return;
  }

  // Rename key
  const value = sequence.value.source_config.field_mappings.custom_attributes[oldKey];
  delete sequence.value.source_config.field_mappings.custom_attributes[oldKey];
  sequence.value.source_config.field_mappings.custom_attributes[sanitizedKey] = value;
};

const previewNotionRecords = async () => {
  if (!sequence.value.source_config.notion_database_id) {
    useAlert('Selecciona una base de datos de Notion primero');
    return;
  }

  await queryNotionDatabase(sequence.value.source_config.notion_database_id);
};

const previewNotionRecordsWithFilters = async () => {
  if (!sequence.value.source_config.notion_database_id) {
    useAlert('Selecciona una base de datos de Notion primero');
    return;
  }

  // Build filters object to send to backend
  const filters = {};

  // Add date filters
  if (sequence.value.source_config.notion_filters?.date_filters?.length > 0) {
    filters.date_filters = sequence.value.source_config.notion_filters.date_filters.filter(
      f => f.field_name && (f.operator === 'between' ? (f.from_date && f.to_date) : f.days)
    );
  }

  // Add select filters
  if (sequence.value.source_config.notion_filters?.select_filters?.length > 0) {
    filters.select_filters = sequence.value.source_config.notion_filters.select_filters.filter(
      f => f.field_name && f.value
    );
  }

  // Query with filters
  await queryNotionDatabase(
    sequence.value.source_config.notion_database_id,
    filters
  );

  // Open modal
  showNotionPreviewModal.value = true;
};

const formatDate = dateString => {
  if (!dateString) return '-';

  // Parse date as local (avoid timezone conversion issues)
  // Notion dates come as "YYYY-MM-DD", adding time keeps it in local timezone
  const [year, month, day] = dateString.split('-');
  const localDate = new Date(year, month - 1, day);

  return localDate.toLocaleDateString('es-MX', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
};

const extractPreviewValue = (record, fieldName) => {
  if (!record || !fieldName) return '-';

  const mappings = sequence.value.source_config.field_mappings;
  let notionField = null;

  // Find which Notion field maps to this field
  if (fieldName === 'phone') {
    notionField = mappings.phone_number;
  } else if (fieldName === 'name') {
    notionField = mappings.name;
  } else if (fieldName === 'date') {
    notionField = mappings.reference_date;
  }

  if (!notionField || !record.properties) return '-';

  const property = record.properties[notionField];
  if (!property) return '-';

  // Extract value based on property type
  switch (property.type) {
    case 'title':
      return property.title?.[0]?.plain_text || '-';
    case 'rich_text':
      return property.rich_text?.[0]?.plain_text || '-';
    case 'phone_number':
      return property.phone_number || '-';
    case 'date':
      return property.date?.start || '-';
    default:
      return '-';
  }
};

// Notion Filters
const addSelectFilter = () => {
  if (!sequence.value.source_config.notion_filters) {
    sequence.value.source_config.notion_filters = {
      select_filters: [],
      date_filters: [],
      checkbox_filters: [],
    };
  }
  sequence.value.source_config.notion_filters.select_filters.push({
    id: `filter_${Date.now()}`,
    field_name: '',
    operator: 'equals',
    value: '',
  });
};

const removeSelectFilter = index => {
  sequence.value.source_config.notion_filters.select_filters.splice(index, 1);
};

const addDateFilter = () => {
  if (!sequence.value.source_config.notion_filters) {
    sequence.value.source_config.notion_filters = {
      select_filters: [],
      date_filters: [],
      checkbox_filters: [],
    };
  }
  sequence.value.source_config.notion_filters.date_filters.push({
    id: `filter_${Date.now()}`,
    field_name: '',
    operator: 'older_than', // 'older_than' | 'newer_than' | 'between'
    days: 30,
    from_date: null,
    to_date: null,
  });
};

const removeDateFilter = index => {
  sequence.value.source_config.notion_filters.date_filters.splice(index, 1);
};

const addCheckboxFilter = () => {
  if (!sequence.value.source_config.notion_filters) {
    sequence.value.source_config.notion_filters = {
      select_filters: [],
      date_filters: [],
      checkbox_filters: [],
    };
  }
  sequence.value.source_config.notion_filters.checkbox_filters.push({
    id: `filter_${Date.now()}`,
    field_name: '',
    value: true,
  });
};

const removeCheckboxFilter = index => {
  sequence.value.source_config.notion_filters.checkbox_filters.splice(index, 1);
};

// Get date fields
const notionDateFieldsForFilters = computed(() => {
  if (!databaseSchema.value?.properties) return [];
  return databaseSchema.value.properties.filter(p => p.type === 'date');
});

// Get select fields with options
const notionSelectFields = computed(() => {
  if (!databaseSchema.value?.properties) return [];
  return databaseSchema.value.properties.filter(p =>
    ['select', 'multi_select'].includes(p.type)
  );
});

// Get checkbox fields
const notionCheckboxFields = computed(() => {
  if (!databaseSchema.value?.properties) return [];
  return databaseSchema.value.properties.filter(p => p.type === 'checkbox');
});

// Get options for a select field
const getSelectFieldOptions = fieldName => {
  const field = databaseSchema.value?.properties?.find(
    p => p.name === fieldName
  );
  return field?.options || [];
};

const saveSequence = async () => {
  if (!sequence.value.name) {
    useAlert(t('LEAD_RETARGETING.FORM.NAME_REQUIRED'));
    return;
  }

  // Validate based on source type
  if (sequence.value.source_type === 'existing_conversations') {
    if (!sequence.value.inbox_id) {
      useAlert(t('LEAD_RETARGETING.FORM.INBOX_REQUIRED'));
      return;
    }
  } else if (sequence.value.source_type === 'notion_database') {
    // Validate Notion configuration
    if (!sequence.value.source_config.notion_database_id) {
      useAlert('Selecciona una base de datos de Notion');
      return;
    }

    if (!sequence.value.source_config.field_mappings.phone_number) {
      useAlert('El campo de Teléfono es obligatorio');
      return;
    }
  }

  // Validar filtro de fechas
  const dateFilter = sequence.value.trigger_conditions.date_filter;
  if (dateFilter.enabled) {
    if (dateFilter.operator === 'between') {
      if (!dateFilter.from_date || !dateFilter.to_date) {
        useAlert(t('LEAD_RETARGETING.FORM.DATE_RANGE_REQUIRED'));
        return;
      }
    } else if (!dateFilter.value || dateFilter.value <= 0) {
      useAlert(t('LEAD_RETARGETING.FORM.DATE_VALUE_REQUIRED'));
      return;
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
  const pipelineStatusFilter =
    sequence.value.trigger_conditions.pipeline_status_filter;
  if (
    pipelineStatusFilter.enabled &&
    pipelineStatusFilter.pipeline_status_ids.length === 0
  ) {
    useAlert(t('LEAD_RETARGETING.FORM.PIPELINE_STATUSES_REQUIRED'));
    return;
  }

  // Validaciones específicas para copilots de Notion
  if (sequence.value.source_type === 'notion_database') {
    if (!sequence.value.steps || sequence.value.steps.length === 0) {
      useAlert(
        'Debes agregar al menos el paso "Primer Contacto" para el copilot de Notion'
      );
      return;
    }

    const firstStep = sequence.value.steps[0];
    if (firstStep.type !== 'first_contact') {
      useAlert(
        'El primer paso debe ser "Primer Contacto" para copilots de Notion'
      );
      return;
    }

    // Validar configuración del primer contacto
    if (!firstStep.config.inbox_id) {
      useAlert('Debes seleccionar un inbox en el paso "Primer Contacto"');
      return;
    }

    if (firstStep.config.channel === 'whatsapp') {
      if (!firstStep.config.template_name) {
        useAlert(
          'Debes seleccionar un template de WhatsApp en el paso "Primer Contacto"'
        );
        return;
      }
    }
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
    // Extraer mensaje de error específico del backend
    let errorMessage = isEdit.value
      ? t('LEAD_RETARGETING.FORM.UPDATE_ERROR')
      : t('LEAD_RETARGETING.FORM.CREATE_ERROR');

    if (error.response?.data) {
      const { data } = error.response;

      // Formato 1: { errors: ["mensaje"] }
      if (data.errors && Array.isArray(data.errors) && data.errors.length > 0) {
        errorMessage = data.errors.join(', ');
      }
      // Formato 2: { message: "mensaje" }
      else if (data.message) {
        errorMessage = data.message;
      }
    }

    useAlert(errorMessage);
  } finally {
    loading.value = false;
  }
};
</script>

<template>
  <div
    class="overflow-auto flex-grow flex-shrink pr-0 pl-0 w-full min-w-0 settings"
  >
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
        <!-- Flow Type Selection -->
        <SettingsSection
          title="Tipo de Flujo"
          sub-title="Selecciona cómo quieres que se inicie este copilot"
        >
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <!-- Existing Conversations Option -->
            <button
              type="button"
              class="border-2 rounded-lg p-6 text-left transition-all"
              :class="[
                sequence.source_type === 'existing_conversations'
                  ? 'border-n-blue-9 bg-n-blue-2 dark:bg-n-blue-3'
                  : 'border-n-weak hover:border-n-blue-6',
              ]"
              @click="sequence.source_type = 'existing_conversations'"
            >
              <div class="flex items-start space-x-3">
                <i class="i-lucide-refresh-ccw text-2xl text-n-blue-9 mt-1" />
                <div class="flex-1">
                  <h3 class="font-semibold text-base text-n-slate-12 mb-1">
                    Seguimiento
                  </h3>
                  <p class="text-sm text-n-slate-11">
                    Da seguimiento a conversaciones existentes que ya están en
                    tu inbox
                  </p>
                </div>
                <i
                  v-if="sequence.source_type === 'existing_conversations'"
                  class="i-lucide-check-circle text-xl text-n-blue-9"
                />
              </div>
            </button>

            <!-- Notion Database Option -->
            <button
              type="button"
              class="border-2 rounded-lg p-6 text-left transition-all"
              :class="[
                sequence.source_type === 'notion_database'
                  ? 'border-n-blue-9 bg-n-blue-2 dark:bg-n-blue-3'
                  : 'border-n-weak hover:border-n-blue-6',
              ]"
              @click="sequence.source_type = 'notion_database'"
            >
              <div class="flex items-start space-x-3">
                <i class="i-lucide-database text-2xl text-n-blue-9 mt-1" />
                <div class="flex-1">
                  <h3 class="font-semibold text-base text-n-slate-12 mb-1">
                    Iniciar desde Notion
                  </h3>
                  <p class="text-sm text-n-slate-11">
                    Inicia conversaciones con leads desde una base de datos de
                    Notion
                  </p>
                </div>
                <i
                  v-if="sequence.source_type === 'notion_database'"
                  class="i-lucide-check-circle text-xl text-n-blue-9"
                />
              </div>
            </button>
          </div>
        </SettingsSection>

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
                :placeholder="
                  t('LEAD_RETARGETING.FORM.DESCRIPTION_PLACEHOLDER')
                "
              />
            </div>

            <!-- Inbox only for existing conversations -->
            <div v-if="sequence.source_type === 'existing_conversations'">
              <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
                {{ t('LEAD_RETARGETING.FORM.INBOX') }}
                <span class="text-n-red-10">*</span>
              </label>
              <select
                v-model="sequence.inbox_id"
                class="w-full"
                @change="onInboxChange"
              >
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

        <!-- Notion Integration Section (only for notion_database source) -->
        <SettingsSection
          v-if="sequence.source_type === 'notion_database'"
          title="Integración con Notion"
          sub-title="Configura la base de datos de Notion y mapea los campos"
        >
          <div class="space-y-6">
            <!-- Database Selection -->
            <div class="border border-n-weak/60 rounded-lg p-4">
              <label class="block text-sm font-medium text-n-slate-12 mb-2">
                Base de Datos de Notion
                <span class="text-n-red-10">*</span>
              </label>

              <!-- Loading State -->
              <div
                v-if="notionLoading"
                class="flex items-center gap-2 p-3 bg-n-blue-2 dark:bg-n-blue-3 rounded"
              >
                <i class="i-lucide-loader-2 animate-spin text-n-blue-11" />
                <span class="text-sm text-n-slate-11">Cargando bases de datos de Notion...</span>
              </div>

              <!-- No Databases Found -->
              <div
                v-else-if="notionDatabases.length === 0"
                class="p-4 bg-n-amber-2 dark:bg-n-amber-3 border border-n-amber-6 rounded"
              >
                <div class="flex items-start gap-2">
                  <i
                    class="i-lucide-alert-triangle text-n-amber-11 text-lg mt-0.5"
                  />
                  <div>
                    <p class="text-sm font-medium text-n-amber-11 mb-1">
                      No se encontraron bases de datos
                    </p>
                    <p class="text-xs text-n-slate-11">
                      Asegúrate de haber conectado Notion en
                      <router-link
                        :to="`/app/accounts/${accountId}/settings/integrations/notion`"
                        class="text-n-blue-11 hover:text-n-blue-12 underline"
                      >
                        Integraciones
                      </router-link>
                      y de tener acceso a al menos una base de datos.
                    </p>
                  </div>
                </div>
              </div>

              <!-- Database Selector -->
              <div v-else>
                <select
                  v-model="sequence.source_config.notion_database_id"
                  class="w-full"
                  @change="onNotionDatabaseChange"
                >
                  <option :value="null">Selecciona una base de datos</option>
                  <option
                    v-for="db in notionDatabases"
                    :key="db.id"
                    :value="db.id"
                  >
                    {{ db.title }}
                  </option>
                </select>
                <p class="text-xs text-n-slate-11 mt-2">
                  {{ notionDatabases.length }} base{{
                    notionDatabases.length !== 1 ? 's' : ''
                  }}
                  de datos disponible{{
                    notionDatabases.length !== 1 ? 's' : ''
                  }}
                </p>
              </div>
            </div>

            <!-- Loading Schema State -->
            <div
              v-if="
                sequence.source_config.notion_database_id &&
                !databaseSchema &&
                notionLoading
              "
              class="border border-n-weak/60 rounded-lg p-4"
            >
              <div class="flex items-center gap-2">
                <i class="i-lucide-loader-2 animate-spin text-n-blue-11" />
                <span class="text-sm text-n-slate-11">Cargando schema de la base de datos...</span>
              </div>
            </div>

            <!-- Field Mappings (only show when database is selected and schema is loaded) -->
            <div
              v-if="sequence.source_config.notion_database_id && databaseSchema"
              class="border border-n-weak/60 rounded-lg p-4 space-y-4"
            >
              <div class="flex items-center justify-between">
                <div>
                  <h4 class="font-semibold text-sm text-n-slate-12">
                    Mapeo de Campos
                  </h4>
                  <p class="text-xs text-n-slate-11 mt-1">
                    Relaciona los campos de Notion con los campos del sistema
                  </p>
                </div>
                <span
                  class="text-xs text-n-slate-11 px-2 py-1 bg-n-weak/30 rounded"
                >
                  {{ databaseSchema.properties?.length || 0 }} campos
                  disponibles
                </span>
              </div>

              <!-- Field Mapping Table -->
              <div class="space-y-3">
                <!-- Phone Number (Required) -->
                <div
                  class="grid grid-cols-2 gap-3 items-center p-3 bg-n-slate-2 dark:bg-n-slate-3 rounded"
                >
                  <div class="flex items-center gap-2">
                    <i class="i-lucide-phone text-n-slate-11" />
                    <span class="text-sm font-medium text-n-slate-12">
                      Teléfono
                      <span class="text-n-red-10">*</span>
                    </span>
                  </div>
                  <select
                    v-model="sequence.source_config.field_mappings.phone_number"
                    class="w-full text-sm"
                    :class="{
                      'border-n-red-6':
                        !sequence.source_config.field_mappings.phone_number,
                    }"
                  >
                    <option value="">Selecciona un campo</option>
                    <option
                      v-for="field in notionPhoneFields"
                      :key="field.name"
                      :value="field.name"
                    >
                      {{ field.name }} ({{ field.type }})
                    </option>
                  </select>
                </div>
                <p
                  v-if="notionPhoneFields.length === 0"
                  class="text-xs text-n-amber-11 ml-2"
                >
                  ⚠️ No se encontraron campos de tipo phone_number, rich_text o
                  title. Asegúrate de que tu base de datos tenga un campo para
                  números de teléfono.
                </p>

                <!-- Name -->
                <div
                  class="grid grid-cols-2 gap-3 items-center p-3 hover:bg-n-weak/30 rounded transition-colors"
                >
                  <div class="flex items-center gap-2">
                    <i class="i-lucide-user text-n-slate-11" />
                    <span class="text-sm font-medium text-n-slate-12">Nombre</span>
                  </div>
                  <select
                    v-model="sequence.source_config.field_mappings.name"
                    class="w-full text-sm"
                  >
                    <option value="">Selecciona un campo</option>
                    <option
                      v-for="field in notionTextFields"
                      :key="field.name"
                      :value="field.name"
                    >
                      {{ field.name }} ({{ field.type }})
                    </option>
                  </select>
                </div>

                <!-- Email -->
                <div
                  class="grid grid-cols-2 gap-3 items-center p-3 hover:bg-n-weak/30 rounded transition-colors"
                >
                  <div class="flex items-center gap-2">
                    <i class="i-lucide-mail text-n-slate-11" />
                    <span class="text-sm font-medium text-n-slate-12">Email</span>
                  </div>
                  <select
                    v-model="sequence.source_config.field_mappings.email"
                    class="w-full text-sm"
                  >
                    <option value="">Selecciona un campo</option>
                    <option
                      v-for="field in notionEmailFields"
                      :key="field.name"
                      :value="field.name"
                    >
                      {{ field.name }} ({{ field.type }})
                    </option>
                  </select>
                </div>

                <!-- Reference Date -->
                <div
                  class="grid grid-cols-2 gap-3 items-center p-3 hover:bg-n-weak/30 rounded transition-colors"
                >
                  <div class="flex items-center gap-2">
                    <i class="i-lucide-calendar text-n-slate-11" />
                    <div class="flex items-center gap-1">
                      <span class="text-sm font-medium text-n-slate-12">
                        Fecha de Referencia
                      </span>
                      <i
                        v-tooltip.top="
                          'La fecha desde la cual se calcularán los tiempos de espera'
                        "
                        class="i-lucide-help-circle text-xs text-n-slate-11 cursor-help"
                      />
                    </div>
                  </div>
                  <select
                    v-model="
                      sequence.source_config.field_mappings.reference_date
                    "
                    class="w-full text-sm"
                  >
                    <option value="">Ahora (Time.current)</option>
                    <option
                      v-for="field in notionDateFields"
                      :key="field.name"
                      :value="field.name"
                    >
                      {{ field.name }}
                    </option>
                  </select>
                </div>
                <p
                  v-if="notionDateFields.length === 0"
                  class="text-xs text-n-slate-11 ml-2"
                >
                  ℹ️ No se encontraron campos de fecha. Los tiempos de espera se
                  calcularán desde el momento actual.
                </p>
              </div>

              <!-- Custom Attributes -->
              <div class="border-t border-n-weak pt-4 mt-4">
                <div class="flex items-center justify-between mb-3">
                  <div>
                    <h5 class="text-sm font-medium text-n-slate-12">
                      Atributos Personalizados
                    </h5>
                    <p class="text-xs text-n-slate-11 mt-0.5">
                      Campos adicionales que se guardarán en custom_attributes
                      del contacto
                    </p>
                  </div>
                  <Button
                    xs
                    blue
                    faded
                    icon="i-lucide-plus"
                    label="Agregar"
                    @click="addCustomAttribute"
                  />
                </div>

                <!-- Custom Attributes List -->
                <div
                  v-if="
                    Object.keys(
                      sequence.source_config.field_mappings.custom_attributes ||
                        {}
                    ).length > 0
                  "
                  class="space-y-2"
                >
                  <div
                    v-for="(value, key) in sequence.source_config.field_mappings
                      .custom_attributes"
                    :key="key"
                    class="flex items-center gap-2 p-2 bg-n-slate-2 dark:bg-n-slate-3 rounded"
                  >
                    <div class="flex-1">
                      <input
                        :value="key"
                        placeholder="nombre_atributo"
                        class="w-full text-sm px-2 py-1 rounded border border-n-weak/60 font-mono text-n-slate-12 focus:border-n-blue-9 focus:ring-1 focus:ring-n-blue-9"
                        @blur="e => renameCustomAttributeKey(key, e.target.value)"
                      />
                      <p class="text-xs text-n-slate-11 mt-0.5">
                        Key que se guardará en custom_attributes
                      </p>
                    </div>
                    <i class="i-lucide-arrow-right text-n-slate-11" />
                    <div class="flex-1">
                      <select
                        v-model="
                          sequence.source_config.field_mappings.custom_attributes[
                            key
                          ]
                        "
                        class="w-full text-sm"
                      >
                        <option value="">Selecciona campo de Notion</option>
                        <option
                          v-for="field in notionAllFields"
                          :key="field.name"
                          :value="field.name"
                        >
                          {{ field.name }} ({{ field.type }})
                        </option>
                      </select>
                      <p class="text-xs text-n-slate-11 mt-0.5">
                        Campo de Notion a mapear
                      </p>
                    </div>
                    <Button
                      xs
                      ruby
                      faded
                      icon="i-lucide-x"
                      @click="removeCustomAttribute(key)"
                    />
                  </div>
                </div>

                <!-- Empty State -->
                <div
                  v-else
                  class="text-center py-6 border border-dashed border-n-weak rounded"
                >
                  <i
                    class="i-lucide-package-plus text-3xl text-n-slate-11 mb-2"
                  />
                  <p class="text-sm text-n-slate-11">
                    No hay atributos personalizados configurados
                  </p>
                  <p class="text-xs text-n-slate-11 mt-1">
                    Haz clic en "Agregar" para mapear campos adicionales de
                    Notion
                  </p>
                </div>
              </div>

              <!-- Preview Records -->
              <div class="border-t border-n-weak pt-4 mt-4">
                <Button
                  xs
                  blue
                  faded
                  label="Vista Previa de Registros"
                  icon="i-lucide-eye"
                  :is-loading="notionLoadingPreview"
                  @click="previewNotionRecords"
                />

                <div
                  v-if="notionRecordsPreview.length > 0"
                  class="mt-4 border border-n-weak/60 rounded-lg overflow-hidden"
                >
                  <table class="min-w-full divide-y divide-n-weak">
                    <thead class="bg-n-slate-2 dark:bg-n-slate-3">
                      <tr>
                        <th
                          class="px-4 py-2 text-left text-xs font-medium text-n-slate-11"
                        >
                          Nombre
                        </th>
                        <th
                          class="px-4 py-2 text-left text-xs font-medium text-n-slate-11"
                        >
                          Teléfono
                        </th>
                        <th
                          class="px-4 py-2 text-left text-xs font-medium text-n-slate-11"
                        >
                          Fecha Ref.
                        </th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-n-weak">
                      <tr
                        v-for="record in notionRecordsPreview.slice(0, 5)"
                        :key="record.id"
                        class="hover:bg-n-weak/30"
                      >
                        <td class="px-4 py-2 text-sm text-n-slate-12">
                          {{ extractPreviewValue(record, 'name') }}
                        </td>
                        <td class="px-4 py-2 text-sm text-n-slate-12">
                          {{ extractPreviewValue(record, 'phone') }}
                        </td>
                        <td class="px-4 py-2 text-sm text-n-slate-11">
                          {{ formatDate(extractPreviewValue(record, 'date')) }}
                        </td>
                      </tr>
                    </tbody>
                  </table>
                  <div
                    class="px-4 py-2 bg-n-blue-2 dark:bg-n-blue-3 text-xs text-n-slate-11"
                  >
                    Mostrando primeros 5 de
                    {{ notionRecordsPreview.length }} registros
                  </div>
                </div>
              </div>
            </div>
          </div>
        </SettingsSection>

        <!-- Notion Filters Section -->
        <SettingsSection
          v-if="sequence.source_type === 'notion_database' && databaseSchema"
          title="Filtros de Notion"
          sub-title="Filtra qué registros de Notion serán procesados"
        >
          <div class="space-y-6">
            <!-- Date Filters -->
            <div class="border border-n-weak/60 rounded-lg p-4">
              <div class="flex items-center justify-between mb-4">
                <div>
                  <h4 class="font-semibold text-sm text-n-slate-12">Filtros por Fecha</h4>
                  <p class="text-xs text-n-slate-11 mt-1">Filtra registros basándote en campos de fecha</p>
                </div>
                <Button
                  xs
                  slate
                  faded
                  label="+ Agregar Filtro"
                  icon="i-lucide-calendar-plus"
                  :disabled="notionDateFieldsForFilters.length === 0"
                  @click="addDateFilter"
                />
              </div>

              <div v-if="notionDateFieldsForFilters.length === 0" class="text-center py-4 text-xs text-n-amber-11">
                No hay campos de tipo fecha disponibles en esta base de datos
              </div>

              <div v-else-if="sequence.source_config.notion_filters.date_filters.length === 0" class="text-center py-4 border border-dashed border-n-weak rounded">
                <i class="i-lucide-calendar-off text-2xl text-n-slate-11 mb-2" />
                <p class="text-sm text-n-slate-11">No hay filtros de fecha configurados</p>
              </div>

              <div v-else class="space-y-3">
                <div
                  v-for="(filter, index) in sequence.source_config.notion_filters.date_filters"
                  :key="filter.id"
                  class="border border-n-weak/60 rounded-lg p-3 space-y-3"
                >
                  <div class="flex items-center justify-between">
                    <span class="text-xs font-medium text-n-slate-11">Filtro de Fecha {{ index + 1 }}</span>
                    <button
                      type="button"
                      class="text-n-red-11 hover:text-n-red-12 transition-colors"
                      @click="removeDateFilter(index)"
                    >
                      <i class="i-lucide-trash-2 text-sm" />
                    </button>
                  </div>

                  <!-- Field Selection -->
                  <div>
                    <label class="block text-xs font-medium text-n-slate-12 mb-1">Campo de Fecha</label>
                    <select v-model="filter.field_name" class="w-full text-sm">
                      <option value="">Selecciona un campo</option>
                      <option v-for="field in notionDateFieldsForFilters" :key="field.name" :value="field.name">
                        {{ field.name }}
                      </option>
                    </select>
                  </div>

                  <!-- Operator Selection -->
                  <div>
                    <label class="block text-xs font-medium text-n-slate-12 mb-1">Condición</label>
                    <select v-model="filter.operator" class="w-full text-sm">
                      <option value="older_than">Más antiguo que</option>
                      <option value="newer_than">Más reciente que</option>
                      <option value="between">Entre fechas</option>
                    </select>
                  </div>

                  <!-- Days input (for older_than / newer_than) -->
                  <div v-if="filter.operator !== 'between'">
                    <label class="block text-xs font-medium text-n-slate-12 mb-1">Cantidad de días</label>
                    <input
                      v-model.number="filter.days"
                      type="number"
                      min="1"
                      class="w-full text-sm"
                      placeholder="30"
                    />
                  </div>

                  <!-- Date range (for between) -->
                  <div v-else class="grid grid-cols-2 gap-3">
                    <div>
                      <label class="block text-xs font-medium text-n-slate-12 mb-1">Desde</label>
                      <input
                        v-model="filter.from_date"
                        type="date"
                        class="w-full text-sm"
                      />
                    </div>
                    <div>
                      <label class="block text-xs font-medium text-n-slate-12 mb-1">Hasta</label>
                      <input
                        v-model="filter.to_date"
                        type="date"
                        class="w-full text-sm"
                      />
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Select Filters -->
            <div class="border border-n-weak/60 rounded-lg p-4">
              <div class="flex items-center justify-between mb-4">
                <div>
                  <h4 class="font-semibold text-sm text-n-slate-12">Filtros por Select</h4>
                  <p class="text-xs text-n-slate-11 mt-1">Filtra registros basándote en campos de selección</p>
                </div>
                <Button
                  xs
                  slate
                  faded
                  label="+ Agregar Filtro"
                  icon="i-lucide-list-plus"
                  :disabled="notionSelectFields.length === 0"
                  @click="addSelectFilter"
                />
              </div>

              <div v-if="notionSelectFields.length === 0" class="text-center py-4 text-xs text-n-amber-11">
                No hay campos de tipo select disponibles en esta base de datos
              </div>

              <div v-else-if="sequence.source_config.notion_filters.select_filters.length === 0" class="text-center py-4 border border-dashed border-n-weak rounded">
                <i class="i-lucide-list-x text-2xl text-n-slate-11 mb-2" />
                <p class="text-sm text-n-slate-11">No hay filtros de select configurados</p>
              </div>

              <div v-else class="space-y-3">
                <div
                  v-for="(filter, index) in sequence.source_config.notion_filters.select_filters"
                  :key="filter.id"
                  class="border border-n-weak/60 rounded-lg p-3 space-y-3"
                >
                  <div class="flex items-center justify-between">
                    <span class="text-xs font-medium text-n-slate-11">Filtro de Select {{ index + 1 }}</span>
                    <button
                      type="button"
                      class="text-n-red-11 hover:text-n-red-12 transition-colors"
                      @click="removeSelectFilter(index)"
                    >
                      <i class="i-lucide-trash-2 text-sm" />
                    </button>
                  </div>

                  <!-- Field Selection -->
                  <div>
                    <label class="block text-xs font-medium text-n-slate-12 mb-1">Campo de Select</label>
                    <select v-model="filter.field_name" class="w-full text-sm" @change="filter.value = ''">
                      <option value="">Selecciona un campo</option>
                      <option v-for="field in notionSelectFields" :key="field.name" :value="field.name">
                        {{ field.name }} ({{ field.type }})
                      </option>
                    </select>
                  </div>

                  <!-- Value Selection (based on field options) -->
                  <div v-if="filter.field_name">
                    <label class="block text-xs font-medium text-n-slate-12 mb-1">Valor</label>
                    <select v-model="filter.value" class="w-full text-sm">
                      <option value="">Selecciona un valor</option>
                      <option
                        v-for="option in getSelectFieldOptions(filter.field_name)"
                        :key="option.id"
                        :value="option.name"
                      >
                        {{ option.name }}
                      </option>
                    </select>
                  </div>
                </div>
              </div>
            </div>

            <div class="p-3 bg-n-blue-2 dark:bg-n-blue-3 border border-n-blue-6 rounded-lg">
              <div class="flex items-start gap-2">
                <i class="i-lucide-info text-n-blue-11 text-sm mt-0.5" />
                <div class="text-xs text-n-slate-11">
                  <p class="font-medium text-n-blue-11 mb-1">Acerca de los filtros</p>
                  <p>Los filtros se aplicarán al consultar la base de datos de Notion. Solo los registros que cumplan <strong>todos</strong> los filtros configurados serán procesados.</p>
                </div>
              </div>
            </div>

            <!-- Preview Button -->
            <div class="flex justify-end">
              <Button
                xs
                teal
                faded
                label="Vista Previa de Registros Filtrados"
                icon="i-lucide-filter"
                :is-loading="notionLoadingPreview"
                :disabled="!sequence.source_config.notion_database_id"
                @click="previewNotionRecordsWithFilters"
              />
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
                v-model="sequence.settings.stop_on_agent_assigned"
                type="checkbox"
                class="rounded"
              />
              <span class="text-sm text-n-slate-11">
                {{ t('LEAD_RETARGETING.FORM.STOP_ON_AGENT_ASSIGNED') }}
              </span>
            </label>

            <label class="flex items-center gap-2 cursor-pointer">
              <input
                v-model="sequence.settings.stop_on_agent_reply"
                type="checkbox"
                class="rounded"
              />
              <span class="text-sm text-n-slate-11">
                {{ t('LEAD_RETARGETING.FORM.STOP_ON_AGENT_REPLY') }}
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

        <!-- Reactivation Filters (only for existing_conversations) -->
        <SettingsSection
          v-if="sequence.source_type === 'existing_conversations'"
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

              <div
                v-if="sequence.trigger_conditions.date_filter.enabled"
                class="space-y-3 pl-6"
              >
                <!-- Filter Type Select -->
                <div>
                  <label
                    class="block text-sm font-medium text-n-slate-12 mb-1.5"
                  >
                    {{ t('LEAD_RETARGETING.FORM.DATE_FILTER_TYPE') }}
                  </label>
                  <select
                    v-model="
                      sequence.trigger_conditions.date_filter.filter_type
                    "
                    class="w-full"
                  >
                    <option value="conversation_created_at">
                      {{
                        t(
                          'LEAD_RETARGETING.FORM.DATE_FILTER_CONVERSATION_CREATED'
                        )
                      }}
                    </option>
                    <option value="last_message_at">
                      {{ t('LEAD_RETARGETING.FORM.DATE_FILTER_LAST_MESSAGE') }}
                    </option>
                    <option value="inactive_days">
                      {{ t('LEAD_RETARGETING.FORM.DATE_FILTER_INACTIVE_DAYS') }}
                    </option>
                  </select>
                </div>

                <!-- Operator Select -->
                <div>
                  <label
                    class="block text-sm font-medium text-n-slate-12 mb-1.5"
                  >
                    {{ t('LEAD_RETARGETING.FORM.DATE_OPERATOR') }}
                  </label>
                  <select
                    v-model="sequence.trigger_conditions.date_filter.operator"
                    class="w-full"
                  >
                    <option value="older_than">
                      {{ t('LEAD_RETARGETING.FORM.DATE_OPERATOR_OLDER_THAN') }}
                    </option>
                    <option value="newer_than">
                      {{ t('LEAD_RETARGETING.FORM.DATE_OPERATOR_NEWER_THAN') }}
                    </option>
                    <option value="between">
                      {{ t('LEAD_RETARGETING.FORM.DATE_OPERATOR_BETWEEN') }}
                    </option>
                  </select>
                </div>

                <!-- Days Input (for relative operators) -->
                <div
                  v-if="
                    sequence.trigger_conditions.date_filter.operator !==
                    'between'
                  "
                  class="flex gap-2 items-center"
                >
                  <input
                    v-model.number="
                      sequence.trigger_conditions.date_filter.value
                    "
                    type="number"
                    min="1"
                    class="w-32 px-3 py-2"
                    :placeholder="t('LEAD_RETARGETING.FORM.DAYS')"
                  />
                  <span class="text-sm text-n-slate-11">{{
                    t('LEAD_RETARGETING.FORM.DAYS')
                  }}</span>
                </div>

                <!-- Date Range (for between operator) -->
                <div
                  v-if="
                    sequence.trigger_conditions.date_filter.operator ===
                    'between'
                  "
                  class="grid grid-cols-2 gap-3"
                >
                  <div>
                    <label
                      class="block text-xs font-medium text-n-slate-12 mb-1"
                    >
                      {{ t('LEAD_RETARGETING.FORM.FROM_DATE') }}
                    </label>
                    <input
                      v-model="
                        sequence.trigger_conditions.date_filter.from_date
                      "
                      type="date"
                      class="w-full"
                    />
                  </div>
                  <div>
                    <label
                      class="block text-xs font-medium text-n-slate-12 mb-1"
                    >
                      {{ t('LEAD_RETARGETING.FORM.TO_DATE') }}
                    </label>
                    <input
                      v-model="sequence.trigger_conditions.date_filter.to_date"
                      type="date"
                      class="w-full"
                    />
                  </div>
                </div>

                <!-- Help Text -->
                <div
                  class="text-xs text-n-slate-11 bg-n-blue-2 dark:bg-n-blue-3 p-3 rounded"
                >
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

              <div
                v-if="sequence.trigger_conditions.label_filter.enabled"
                class="space-y-3 pl-6"
              >
                <div>
                  <label
                    class="block text-sm font-medium text-n-slate-12 mb-1.5"
                  >
                    {{ t('LEAD_RETARGETING.FORM.SELECT_LABELS') }}
                  </label>
                  <TagMultiSelectComboBox
                    v-model="sequence.trigger_conditions.label_filter.labels"
                    :options="labelOptions"
                    :placeholder="t('LEAD_RETARGETING.FORM.SELECT_LABELS')"
                    :search-placeholder="
                      t('LEAD_RETARGETING.FORM.SEARCH_LABELS')
                    "
                    :empty-state="t('LEAD_RETARGETING.FORM.NO_LABELS_FOUND')"
                  />
                </div>

                <!-- Help Text -->
                <div
                  class="text-xs text-n-slate-11 bg-n-blue-2 dark:bg-n-blue-3 p-3 rounded"
                >
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

              <div
                v-if="sequence.trigger_conditions.status_filter.enabled"
                class="space-y-3 pl-6"
              >
                <div>
                  <label
                    class="block text-sm font-medium text-n-slate-12 mb-1.5"
                  >
                    {{ t('LEAD_RETARGETING.FORM.SELECT_STATUSES') }}
                  </label>
                  <TagMultiSelectComboBox
                    v-model="sequence.trigger_conditions.status_filter.statuses"
                    :options="statusOptions"
                    :placeholder="t('LEAD_RETARGETING.FORM.SELECT_STATUSES')"
                    :search-placeholder="
                      t('LEAD_RETARGETING.FORM.SEARCH_STATUSES')
                    "
                    :empty-state="t('LEAD_RETARGETING.FORM.NO_STATUSES_FOUND')"
                  />
                </div>

                <!-- Help Text -->
                <div
                  class="text-xs text-n-slate-11 bg-n-blue-2 dark:bg-n-blue-3 p-3 rounded"
                >
                  {{ t('LEAD_RETARGETING.FORM.STATUS_FILTER_HELP') }}
                </div>
              </div>
            </div>

            <!-- Pipeline Status Filter -->
            <div class="border border-n-weak/60 rounded-lg p-4">
              <label class="flex items-center gap-2 cursor-pointer mb-4">
                <input
                  v-model="
                    sequence.trigger_conditions.pipeline_status_filter.enabled
                  "
                  type="checkbox"
                  class="rounded"
                />
                <span class="text-sm font-medium text-n-slate-12">
                  {{ t('LEAD_RETARGETING.FORM.ENABLE_PIPELINE_STATUS_FILTER') }}
                </span>
              </label>

              <div
                v-if="
                  sequence.trigger_conditions.pipeline_status_filter.enabled
                "
                class="space-y-3 pl-6"
              >
                <div>
                  <label
                    class="block text-sm font-medium text-n-slate-12 mb-1.5"
                  >
                    {{ t('LEAD_RETARGETING.FORM.SELECT_PIPELINE_STATUSES') }}
                  </label>
                  <TagMultiSelectComboBox
                    v-model="
                      sequence.trigger_conditions.pipeline_status_filter
                        .pipeline_status_ids
                    "
                    :options="pipelineStatusOptions"
                    :placeholder="
                      t('LEAD_RETARGETING.FORM.SELECT_PIPELINE_STATUSES')
                    "
                    :search-placeholder="
                      t('LEAD_RETARGETING.FORM.SEARCH_PIPELINE_STATUSES')
                    "
                    :empty-state="
                      t('LEAD_RETARGETING.FORM.NO_PIPELINE_STATUSES_FOUND')
                    "
                  />
                </div>

                <!-- Help Text -->
                <div
                  class="text-xs text-n-slate-11 bg-n-blue-2 dark:bg-n-blue-3 p-3 rounded"
                >
                  {{ t('LEAD_RETARGETING.FORM.PIPELINE_STATUS_FILTER_HELP') }}
                </div>
              </div>
            </div>

            <!-- Enrollment Filter -->
            <div class="border border-n-weak/60 rounded-lg p-4">
              <label class="flex items-center gap-2 cursor-pointer">
                <input
                  v-model="
                    sequence.trigger_conditions.enrollment_filter
                      .include_completed
                  "
                  type="checkbox"
                  class="rounded"
                />
                <span class="text-sm font-medium text-n-slate-12">
                  {{ t('LEAD_RETARGETING.FORM.INCLUDE_COMPLETED_COPILOTS') }}
                </span>
              </label>

              <!-- Help Text -->
              <div
                class="mt-3 text-xs text-n-slate-11 bg-n-blue-2 dark:bg-n-blue-3 p-3 rounded"
              >
                {{ t('LEAD_RETARGETING.FORM.INCLUDE_COMPLETED_COPILOTS_HELP') }}
              </div>
            </div>
          </div>

          <!-- Eligible Conversations Preview -->
          <div
            v-if="sequence.inbox_id"
            class="mt-6 p-4 bg-n-blue-2 dark:bg-n-blue-3 rounded-lg border border-n-blue-6"
          >
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
                <div
                  v-else-if="eligibleCount !== null"
                  class="flex items-center gap-2"
                >
                  <span
                    class="px-3 py-1.5 bg-n-blue-9 text-white font-semibold rounded-full text-lg"
                  >
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
              <!-- Primer Contacto (Only for Notion copilots) -->
              <Button
                v-if="canAddFirstContact"
                xs
                teal
                :label="'+ ' + t('LEAD_RETARGETING.STEPS.FIRST_CONTACT.ADD')"
                @click="addStep('first_contact')"
              />
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
                :label="'+ ' + t('LEAD_RETARGETING.STEPS.SEND_MESSAGE.ADD')"
                :disabled="
                  sequence.source_type === 'existing_conversations'
                    ? !sequence.inbox_id
                    : !hasFirstContactStep
                "
                @click="addStep('send_message')"
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
                :label="
                  '+ ' + t('LEAD_RETARGETING.STEPS.UPDATE_PIPELINE_STATUS.ADD')
                "
                @click="addStep('update_pipeline_status')"
              />
              <Button
                xs
                slate
                faded
                :label="'+ ' + t('LEAD_RETARGETING.STEPS.WEBHOOK.ADD')"
                @click="addStep('webhook')"
              />
              <Button
                xs
                slate
                faded
                :label="'+ ' + t('LEAD_RETARGETING.STEPS.SEND_EMAIL.ADD')"
                @click="addStep('send_email')"
              />
            </div>

            <!-- No Steps Message -->
            <div
              v-if="sequence.steps.length === 0"
              class="text-center py-8 text-n-slate-11"
            >
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
                    <span class="text-sm font-medium text-n-slate-11">{{
                      index + 1
                    }}</span>
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

                    <!-- First Contact Step (Notion only) -->
                    <div v-if="step.type === 'first_contact'" class="space-y-3">
                      <div
                        class="p-3 bg-n-teal-2 dark:bg-n-teal-3 border border-n-teal-6 rounded-lg space-y-3"
                      >
                        <label
                          class="block text-xs font-medium text-n-slate-12"
                        >
                          {{ t('LEAD_RETARGETING.STEPS.FIRST_CONTACT.CHANNEL') }}
                          <span class="text-n-red-10">*</span>
                        </label>
                        <div class="flex gap-3">
                          <label
                            class="flex items-center gap-2 cursor-pointer px-3 py-2 border border-n-weak rounded-lg hover:bg-n-weak/30"
                            :class="{
                              'bg-n-teal-4 border-n-teal-8':
                                step.config.channel === 'whatsapp',
                            }"
                          >
                            <input
                              v-model="step.config.channel"
                              type="radio"
                              value="whatsapp"
                              class="text-n-teal-9"
                              @change="onFirstContactChannelChange(step)"
                            />
                            <i class="i-lucide-message-circle text-n-green-9" />
                            <span class="text-sm text-n-slate-12">WhatsApp</span>
                          </label>
                          <label
                            class="flex items-center gap-2 cursor-pointer px-3 py-2 border border-n-weak rounded-lg hover:bg-n-weak/30"
                            :class="{
                              'bg-n-teal-4 border-n-teal-8':
                                step.config.channel === 'sms',
                            }"
                          >
                            <input
                              v-model="step.config.channel"
                              type="radio"
                              value="sms"
                              class="text-n-teal-9"
                              @change="onFirstContactChannelChange(step)"
                            />
                            <i class="i-lucide-mail text-n-blue-9" />
                            <span class="text-sm text-n-slate-12">SMS</span>
                          </label>
                        </div>

                        <!-- Inbox Selection -->
                        <div>
                          <label
                            class="block text-xs font-medium text-n-slate-12 mb-1"
                          >
                            {{ t('LEAD_RETARGETING.STEPS.FIRST_CONTACT.INBOX') }}
                            <span class="text-n-red-10">*</span>
                          </label>
                          <select
                            v-model="step.config.inbox_id"
                            class="w-full text-sm"
                            @change="onFirstContactInboxChange(step)"
                          >
                            <option :value="null">
                              {{ t('LEAD_RETARGETING.STEPS.FIRST_CONTACT.SELECT_INBOX') }}
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

                        <!-- WhatsApp Template Config -->
                        <div
                          v-if="
                            step.config.channel === 'whatsapp' &&
                            step.config.inbox_id
                          "
                          class="space-y-2"
                        >
                          <label
                            class="block text-xs font-medium text-n-slate-12 mb-1"
                          >
                            {{ t('LEAD_RETARGETING.STEPS.FIRST_CONTACT.TEMPLATE') }}
                            <span class="text-n-red-10">*</span>
                          </label>
                          <select
                            v-model="step.config.template_name"
                            class="w-full text-sm"
                            @change="onTemplateChange(step, 'config')"
                          >
                            <option value="">
                              {{ t('LEAD_RETARGETING.STEPS.FIRST_CONTACT.SELECT_TEMPLATE') }}
                            </option>
                            <option
                              v-for="template in availableTemplates"
                              :key="`${template.name}-${template.language}`"
                              :value="template.name"
                            >
                              {{ template.name }} ({{ template.language }})
                            </option>
                          </select>

                          <!-- Template Parameters -->
                          <div
                            v-if="
                              step.config.template_name &&
                              getTemplateParams(step.config.template_name)
                                .length > 0
                            "
                            class="mt-3 space-y-2 p-3 bg-n-slate-2 dark:bg-n-slate-3 rounded"
                          >
                            <label
                              class="block text-xs font-medium text-n-slate-12"
                            >
                              {{ t('LEAD_RETARGETING.STEPS.FIRST_CONTACT.PARAMS') }}
                            </label>
                            <div
                              v-for="(param, idx) in getTemplateParams(
                                step.config.template_name
                              )"
                              :key="idx"
                              class="flex items-center gap-2"
                            >
                              <span class="text-xs text-n-slate-11 w-16">{{ '{' + '{' + (idx + 1) + '}' + '}' }}:</span>
                              <input
                                v-model="
                                  step.config.template_params.body[idx + 1]
                                "
                                type="text"
                                class="flex-1 px-2 py-1 text-sm"
                                :placeholder="`Valor para parámetro ${idx + 1}`"
                              />
                            </div>
                            <div
                              class="mt-2 p-2 bg-n-blue-2 dark:bg-n-blue-3 rounded text-xs"
                            >
                              <p class="font-medium text-n-slate-12 mb-1">
                                Variables disponibles:
                              </p>
                              <div class="flex flex-wrap gap-2">
                                <code
                                  v-for="variable in [
                                    'contact.name',
                                    'contact.phone_number',
                                  ]"
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
                          <div
                            v-if="
                              step.config.template_name &&
                              getTemplatePreview(step, 'config')
                            "
                            class="mt-3 p-3 bg-n-green-2 dark:bg-n-green-3 border border-n-green-6 rounded-lg"
                          >
                            <div class="flex items-start gap-2 mb-1">
                              <i
                                class="i-lucide-eye text-n-green-11 text-sm mt-0.5"
                              />
                              <p class="text-xs font-medium text-n-green-11">
                                {{
                                  t(
                                    'LEAD_RETARGETING.STEPS.FIRST_CONTACT.PREVIEW'
                                  )
                                }}
                              </p>
                            </div>
                            <div
                              class="mt-2 p-3 bg-white dark:bg-n-slate-2 rounded border border-n-weak/60"
                            >
                              <p
                                class="text-sm text-n-slate-12 whitespace-pre-wrap"
                              >
                                {{ getTemplatePreview(step, 'config') }}
                              </p>
                            </div>
                          </div>
                        </div>

                        <!-- SMS Context -->
                        <div
                          v-if="step.config.channel === 'sms'"
                          class="space-y-2"
                        >
                          <label
                            class="block text-xs font-medium text-n-slate-12 mb-1"
                          >
                            {{ t('LEAD_RETARGETING.STEPS.FIRST_CONTACT.SMS_CONTEXT') }}
                            <span class="text-n-slate-11 font-normal">
                              ({{ t('LEAD_RETARGETING.STEPS.SEND_MESSAGE.AI_CONFIG.OPTIONAL') }})
                            </span>
                          </label>
                          <textarea
                            v-model="step.config.sms_context"
                            rows="3"
                            class="w-full text-sm"
                            placeholder="Describe el contexto del mensaje que el AI debería generar..."
                          />
                          <p class="text-xs text-n-slate-11">
                            El AI generará un mensaje SMS basado en este
                            contexto y los datos del contacto.
                          </p>
                        </div>
                      </div>
                    </div>

                    <!-- Wait Step -->
                    <div
                      v-if="step.type === 'wait'"
                      class="flex gap-2 items-center"
                    >
                      <span class="text-sm text-n-slate-11">{{
                        t('LEAD_RETARGETING.STEPS.WAIT.LABEL')
                      }}</span>
                      <input
                        v-model.number="step.config.delay_value"
                        type="number"
                        min="1"
                        class="w-20 px-2 py-1"
                      />
                      <select
                        v-model="step.config.delay_type"
                        class="px-2 py-1"
                      >
                        <option value="minutes">
                          {{ t('LEAD_RETARGETING.STEPS.WAIT.MINUTES') }}
                        </option>
                        <option value="hours">
                          {{ t('LEAD_RETARGETING.STEPS.WAIT.HOURS') }}
                        </option>
                        <option value="days">
                          {{ t('LEAD_RETARGETING.STEPS.WAIT.DAYS') }}
                        </option>
                      </select>
                    </div>

                    <!-- Send Message Step (AI-powered with window detection) -->
                    <div
                      v-else-if="step.type === 'send_message'"
                      class="space-y-4"
                    >
                      <!-- AI Config for Open Window (<24h) -->
                      <div
                        class="p-3 bg-n-blue-2 dark:bg-n-blue-3 border border-n-blue-6 rounded-lg space-y-3"
                      >
                        <div class="flex items-center justify-between">
                          <label
                            class="block text-xs font-medium text-n-slate-12"
                          >
                            {{
                              t(
                                'LEAD_RETARGETING.STEPS.SEND_MESSAGE.AI_CONFIG.TITLE'
                              )
                            }}
                          </label>
                          <input
                            v-model="step.config.ai_config.enabled"
                            type="checkbox"
                            class="rounded"
                          />
                        </div>

                        <div
                          v-if="step.config.ai_config.enabled"
                          class="space-y-2"
                        >
                          <!-- Context (Optional) -->
                          <div>
                            <label
                              class="block text-xs font-medium text-n-slate-12 mb-1"
                            >
                              {{
                                t(
                                  'LEAD_RETARGETING.STEPS.SEND_MESSAGE.AI_CONFIG.CONTEXT'
                                )
                              }}
                              <span class="text-n-slate-11 font-normal">({{
                                  t(
                                    'LEAD_RETARGETING.STEPS.SEND_MESSAGE.AI_CONFIG.OPTIONAL'
                                  )
                                }})</span>
                            </label>
                            <textarea
                              v-model="step.config.ai_config.context"
                              rows="3"
                              class="w-full text-sm"
                              :placeholder="
                                t(
                                  'LEAD_RETARGETING.STEPS.SEND_MESSAGE.AI_CONFIG.CONTEXT_PLACEHOLDER'
                                )
                              "
                            />
                            <p class="text-xs text-n-slate-11 mt-1">
                              {{
                                t(
                                  'LEAD_RETARGETING.STEPS.SEND_MESSAGE.AI_CONFIG.CONTEXT_HELP'
                                )
                              }}
                            </p>
                          </div>
                        </div>
                      </div>

                      <!-- Closed Window Action (>24h) -->
                      <div
                        class="p-3 bg-n-amber-2 dark:bg-n-amber-3 border border-n-amber-6 rounded-lg space-y-3"
                      >
                        <label
                          class="block text-xs font-medium text-n-slate-12"
                        >
                          {{
                            t(
                              'LEAD_RETARGETING.STEPS.SEND_MESSAGE.CLOSED_WINDOW.TITLE'
                            )
                          }}
                        </label>
                        <div class="flex gap-3">
                          <label class="flex items-center gap-2 cursor-pointer">
                            <input
                              v-model="step.config.closed_window_action"
                              type="radio"
                              value="send_template"
                              class="text-n-blue-9"
                            />
                            <span class="text-sm text-n-slate-12">{{
                              t(
                                'LEAD_RETARGETING.STEPS.SEND_MESSAGE.CLOSED_WINDOW.SEND_TEMPLATE'
                              )
                            }}</span>
                          </label>
                          <label class="flex items-center gap-2 cursor-pointer">
                            <input
                              v-model="step.config.closed_window_action"
                              type="radio"
                              value="send_sms"
                              class="text-n-blue-9"
                            />
                            <span class="text-sm text-n-slate-12">{{
                              t(
                                'LEAD_RETARGETING.STEPS.SEND_MESSAGE.CLOSED_WINDOW.SEND_SMS'
                              )
                            }}</span>
                          </label>
                        </div>

                        <!-- Template Config (if send_template) -->
                        <div
                          v-if="
                            step.config.closed_window_action === 'send_template'
                          "
                          class="space-y-2 mt-3 pt-3 border-t border-n-amber-6"
                        >
                          <div>
                            <label
                              class="block text-xs font-medium text-n-slate-12 mb-1"
                              >Template</label>
                            <select
                              v-model="
                                step.config.template_config.template_name
                              "
                              class="w-full text-sm"
                              @change="
                                onTemplateChange(step, 'template_config')
                              "
                            >
                              <option value="">
                                {{
                                  t(
                                    'LEAD_RETARGETING.STEPS.SEND_TEMPLATE.SELECT'
                                  )
                                }}
                              </option>
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
                          <div
                            v-if="step.config.template_config.template_name"
                            class="flex items-center gap-2"
                          >
                            <span class="text-xs text-n-slate-11">Categoría:</span>
                            <span
                              class="text-xs px-2 py-1 rounded font-medium"
                              :class="
                                getCategoryColor(
                                  getTemplateCategory(
                                    step.config.template_config.template_name
                                  )
                                )
                              "
                            >
                              {{
                                getCategoryLabel(
                                  getTemplateCategory(
                                    step.config.template_config.template_name
                                  )
                                )
                              }}
                            </span>
                          </div>

                          <!-- Template Parameters -->
                          <div
                            v-if="
                              step.config.template_config.template_name &&
                              getTemplateParams(
                                step.config.template_config.template_name
                              ).length > 0
                            "
                            class="space-y-2 p-3 bg-white/50 dark:bg-n-slate-1/50 rounded"
                          >
                            <label
                              class="block text-xs font-medium text-n-slate-12 mb-2"
                              >Parámetros del Template</label>
                            <div
                              v-for="(param, idx) in getTemplateParams(
                                step.config.template_config.template_name
                              )"
                              :key="idx"
                              class="flex items-center gap-2"
                            >
                              <span class="text-xs text-n-slate-11 w-16">{{ '{' + '{' + (idx + 1) + '}' + '}' }}:</span>
                              <input
                                v-model="
                                  step.config.template_config.template_params
                                    .body[idx + 1]
                                "
                                type="text"
                                class="flex-1 px-2 py-1 text-sm"
                                :placeholder="`Valor para parámetro ${idx + 1}`"
                              />
                            </div>
                            <div
                              class="mt-2 p-2 bg-n-blue-2 dark:bg-n-blue-3 rounded text-xs"
                            >
                              <p class="font-medium text-n-slate-12 mb-1">
                                Variables disponibles:
                              </p>
                              <div class="flex flex-wrap gap-2">
                                <code
                                  v-for="variable in [
                                    'contact.name',
                                    'contact.email',
                                    'contact.phone_number',
                                  ]"
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
                          <div
                            v-if="
                              step.config.template_config.template_name &&
                              getTemplatePreview(step, 'template_config')
                            "
                            class="p-3 bg-n-green-2 dark:bg-n-green-3 border border-n-green-6 rounded-lg"
                          >
                            <div class="flex items-start gap-2 mb-1">
                              <i
                                class="i-lucide-eye text-n-green-11 text-sm mt-0.5"
                              />
                              <p class="text-xs font-medium text-n-green-11">
                                {{
                                  t(
                                    'LEAD_RETARGETING.STEPS.FIRST_CONTACT.PREVIEW'
                                  )
                                }}
                              </p>
                            </div>
                            <div
                              class="mt-2 p-3 bg-white dark:bg-n-slate-2 rounded border border-n-weak/60"
                            >
                              <p
                                class="text-sm text-n-slate-12 whitespace-pre-wrap"
                              >
                                {{
                                  getTemplatePreview(step, 'template_config')
                                }}
                              </p>
                            </div>
                          </div>
                        </div>

                        <!-- SMS Config (if send_sms) -->
                        <div
                          v-if="step.config.closed_window_action === 'send_sms'"
                          class="space-y-2 mt-3 pt-3 border-t border-n-amber-6"
                        >
                          <!-- SMS Context (Optional) -->
                          <div>
                            <label
                              class="block text-xs font-medium text-n-slate-12 mb-1"
                            >
                              {{
                                t(
                                  'LEAD_RETARGETING.STEPS.SEND_MESSAGE.SMS_CONFIG.CONTEXT'
                                )
                              }}
                              <span class="text-n-slate-11 font-normal">({{
                                  t(
                                    'LEAD_RETARGETING.STEPS.SEND_MESSAGE.SMS_CONFIG.OPTIONAL'
                                  )
                                }})</span>
                            </label>
                            <textarea
                              v-model="step.config.sms_config.context"
                              rows="3"
                              class="w-full text-sm"
                              :placeholder="
                                t(
                                  'LEAD_RETARGETING.STEPS.SEND_MESSAGE.SMS_CONFIG.CONTEXT_PLACEHOLDER'
                                )
                              "
                            />
                            <p class="text-xs text-n-slate-11 mt-1">
                              {{
                                t(
                                  'LEAD_RETARGETING.STEPS.SEND_MESSAGE.SMS_CONFIG.CONTEXT_HELP'
                                )
                              }}
                            </p>
                          </div>
                        </div>
                      </div>
                    </div>

                    <!-- Send Email Step -->
                    <div
                      v-else-if="step.type === 'send_email'"
                      class="space-y-4"
                    >
                      <div
                        class="p-3 bg-n-amber-2 dark:bg-n-amber-3 border border-n-amber-6 rounded-lg space-y-3"
                      >
                        <!-- Sender Email -->
                        <div>
                          <label
                            class="block text-xs font-medium text-n-slate-12 mb-1"
                          >
                            {{ t('LEAD_RETARGETING.STEPS.SEND_EMAIL.SENDER_EMAIL') }}
                          </label>
                          <input
                            v-model="step.config.sender_email"
                            type="email"
                            class="w-full text-sm"
                            :placeholder="
                              t(
                                'LEAD_RETARGETING.STEPS.SEND_EMAIL.SENDER_EMAIL_PLACEHOLDER'
                              )
                            "
                          />
                        </div>

                        <!-- Subject -->
                        <div>
                          <label
                            class="block text-xs font-medium text-n-slate-12 mb-1"
                          >
                            {{ t('LEAD_RETARGETING.STEPS.SEND_EMAIL.SUBJECT') }}
                          </label>
                          <input
                            v-model="step.config.subject"
                            type="text"
                            class="w-full text-sm"
                            :placeholder="
                              t(
                                'LEAD_RETARGETING.STEPS.SEND_EMAIL.SUBJECT_PLACEHOLDER'
                              )
                            "
                          />
                        </div>

                        <!-- Content -->
                        <div>
                          <label
                            class="block text-xs font-medium text-n-slate-12 mb-1"
                          >
                            {{ t('LEAD_RETARGETING.STEPS.SEND_EMAIL.CONTENT') }}
                          </label>
                          <textarea
                            v-model="step.config.content"
                            rows="5"
                            class="w-full text-sm font-mono"
                            :placeholder="
                              t(
                                'LEAD_RETARGETING.STEPS.SEND_EMAIL.CONTENT_PLACEHOLDER'
                              )
                            "
                          />
                          <p class="text-xs text-n-slate-11 mt-1">
                            {{
                              t('LEAD_RETARGETING.STEPS.SEND_EMAIL.VARIABLES_HINT')
                            }}
                          </p>
                        </div>
                      </div>
                    </div>

                    <!-- Add Label Step -->
                    <div v-else-if="step.type === 'add_label'" class="space-y-2">
                      <label
                        class="block text-xs font-medium text-n-slate-12 mb-1"
                      >
                        {{ t('LEAD_RETARGETING.STEPS.ADD_LABEL.SELECT_LABEL') }}
                      </label>
                      <select v-model="step.config.labels[0]" class="w-full">
                        <option value="">
                          {{
                            t('LEAD_RETARGETING.STEPS.ADD_LABEL.PLACEHOLDER')
                          }}
                        </option>
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
                    <div
                      v-else-if="step.type === 'remove_label'"
                      class="space-y-2"
                    >
                      <label
                        class="block text-xs font-medium text-n-slate-12 mb-1"
                      >
                        {{
                          t('LEAD_RETARGETING.STEPS.REMOVE_LABEL.SELECT_LABEL')
                        }}
                      </label>
                      <select v-model="step.config.labels[0]" class="w-full">
                        <option value="">
                          {{
                            t('LEAD_RETARGETING.STEPS.REMOVE_LABEL.PLACEHOLDER')
                          }}
                        </option>
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
                    <div
                      v-else-if="step.type === 'assign_agent'"
                      class="space-y-2"
                    >
                      <div>
                        <label
                          class="block text-xs font-medium text-n-slate-12 mb-1"
                        >
                          {{ t('LEAD_RETARGETING.STEPS.ASSIGN_AGENT.TYPE') }}
                        </label>
                        <select
                          v-model="step.config.assignment_type"
                          class="w-full"
                        >
                          <option value="round_robin">
                            {{
                              t(
                                'LEAD_RETARGETING.STEPS.ASSIGN_AGENT.ROUND_ROBIN'
                              )
                            }}
                          </option>
                          <option value="specific_agent">
                            {{
                              t('LEAD_RETARGETING.STEPS.ASSIGN_AGENT.SPECIFIC')
                            }}
                          </option>
                        </select>
                      </div>
                      <div
                        v-if="step.config.assignment_type === 'specific_agent'"
                      >
                        <label
                          class="block text-xs font-medium text-n-slate-12 mb-1"
                        >
                          {{
                            t(
                              'LEAD_RETARGETING.STEPS.ASSIGN_AGENT.SELECT_AGENT'
                            )
                          }}
                        </label>
                        <select v-model="step.config.agent_id" class="w-full">
                          <option :value="null">
                            {{
                              t(
                                'LEAD_RETARGETING.STEPS.ASSIGN_AGENT.SELECT_PLACEHOLDER'
                              )
                            }}
                          </option>
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
                    <div
                      v-else-if="step.type === 'assign_team'"
                      class="space-y-2"
                    >
                      <label
                        class="block text-xs font-medium text-n-slate-12 mb-1"
                      >
                        {{
                          t('LEAD_RETARGETING.STEPS.ASSIGN_TEAM.SELECT_TEAM')
                        }}
                      </label>
                      <select v-model="step.config.team_id" class="w-full">
                        <option :value="null">
                          {{
                            t(
                              'LEAD_RETARGETING.STEPS.ASSIGN_TEAM.SELECT_PLACEHOLDER'
                            )
                          }}
                        </option>
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
                    <div
                      v-else-if="step.type === 'change_priority'"
                      class="space-y-2"
                    >
                      <label
                        class="block text-xs font-medium text-n-slate-12 mb-1"
                      >
                        {{
                          t(
                            'LEAD_RETARGETING.STEPS.CHANGE_PRIORITY.SELECT_PRIORITY'
                          )
                        }}
                      </label>
                      <select v-model="step.config.priority" class="w-full">
                        <option value="low">
                          {{ t('LEAD_RETARGETING.STEPS.CHANGE_PRIORITY.LOW') }}
                        </option>
                        <option value="medium">
                          {{
                            t('LEAD_RETARGETING.STEPS.CHANGE_PRIORITY.MEDIUM')
                          }}
                        </option>
                        <option value="high">
                          {{ t('LEAD_RETARGETING.STEPS.CHANGE_PRIORITY.HIGH') }}
                        </option>
                        <option value="urgent">
                          {{
                            t('LEAD_RETARGETING.STEPS.CHANGE_PRIORITY.URGENT')
                          }}
                        </option>
                      </select>
                    </div>

                    <!-- Update Pipeline Status Step -->
                    <div
                      v-else-if="step.type === 'update_pipeline_status'"
                      class="space-y-2"
                    >
                      <label
                        class="block text-xs font-medium text-n-slate-12 mb-1"
                      >
                        {{
                          t(
                            'LEAD_RETARGETING.STEPS.UPDATE_PIPELINE_STATUS.SELECT_STATUS'
                          )
                        }}
                      </label>
                      <select
                        v-model="step.config.pipeline_status_id"
                        class="w-full"
                      >
                        <option :value="null">
                          {{
                            t(
                              'LEAD_RETARGETING.STEPS.UPDATE_PIPELINE_STATUS.SELECT_PLACEHOLDER'
                            )
                          }}
                        </option>
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
                        <label
                          class="block text-xs font-medium text-n-slate-12 mb-1"
                        >
                          {{ t('LEAD_RETARGETING.STEPS.WEBHOOK.URL') }}
                        </label>
                        <input
                          v-model="step.config.url"
                          type="url"
                          class="w-full"
                          :placeholder="
                            t('LEAD_RETARGETING.STEPS.WEBHOOK.URL_PLACEHOLDER')
                          "
                        />
                      </div>
                      <div>
                        <label
                          class="block text-xs font-medium text-n-slate-12 mb-1"
                        >
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
      :on-close="() => (showPreviewModal = false)"
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
        <div
          v-if="eligibleConversations.length > 0"
          class="space-y-2 max-h-96 overflow-y-auto"
        >
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
        <div
          class="mt-4 p-3 bg-n-blue-2 dark:bg-n-blue-3 rounded text-xs text-n-slate-11"
        >
          <p>
            Mostrando las primeras
            {{ eligibleConversations.length }} conversaciones.
            {{
              eligibleCount > 20
                ? `Hay ${eligibleCount - 20} más que coinciden con los filtros.`
                : ''
            }}
          </p>
        </div>
      </div>
    </Modal>

    <!-- Notion Records Preview Modal -->
    <Modal
      v-model:show="showNotionPreviewModal"
      :on-close="() => (showNotionPreviewModal = false)"
    >
      <div class="p-6 w-full max-w-3xl">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-lg font-semibold text-n-slate-12">
            Registros de Notion Filtrados
          </h3>
          <span class="text-sm text-n-slate-11">
            Total: {{ notionRecordsPreview.length.toLocaleString() }}
          </span>
        </div>

        <!-- Records List -->
        <div
          v-if="notionRecordsPreview.length > 0"
          class="space-y-2 max-h-96 overflow-y-auto"
        >
          <div
            v-for="record in notionRecordsPreview"
            :key="record.id"
            class="flex items-center gap-3 p-3 border border-n-weak/60 rounded hover:bg-n-weak/30 transition-colors"
          >
            <div class="flex-1 min-w-0">
              <p class="font-medium text-n-slate-12 truncate">
                {{ extractPreviewValue(record, 'name') || 'Sin nombre' }}
              </p>
              <div class="flex items-center gap-2 text-xs text-n-slate-11 mt-1">
                <span v-if="sequence.source_config.field_mappings.phone_number" class="font-mono">
                  {{ extractPreviewValue(record, 'phone') || 'Sin teléfono' }}
                </span>
                <span v-if="sequence.source_config.field_mappings.reference_date" class="text-n-slate-10">
                  • {{ formatDate(extractPreviewValue(record, 'date')) }}
                </span>
              </div>
            </div>
            <span class="text-xs px-2 py-1 bg-n-weak/60 rounded font-mono text-n-slate-11 flex-shrink-0">
              {{ record.id.slice(0, 8) }}
            </span>
          </div>
        </div>

        <!-- Empty State -->
        <div v-else class="py-8 text-center text-n-slate-11">
          <i class="i-lucide-inbox text-4xl mb-2" />
          <p>No hay registros que coincidan con los filtros</p>
        </div>

        <!-- Note -->
        <div
          class="mt-4 p-3 bg-n-blue-2 dark:bg-n-blue-3 rounded text-xs text-n-slate-11"
        >
          <p>
            Mostrando {{ notionRecordsPreview.length }} registros que coinciden con los filtros configurados.
            {{
              notionRecordsPreview.length >= 100
                ? 'Puede haber más registros disponibles.'
                : ''
            }}
          </p>
        </div>
      </div>
    </Modal>
  </div>
</template>
