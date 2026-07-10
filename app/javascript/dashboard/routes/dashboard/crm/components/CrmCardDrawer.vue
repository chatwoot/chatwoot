<script setup>
import { computed, reactive, ref, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import PhoneNumberInput from 'dashboard/components-next/phonenumberinput/PhoneNumberInput.vue';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import ContactAPI from 'dashboard/api/contacts';
import CrmKanbanAPI from 'dashboard/api/crmKanban';
import { relativeTimeFromISO } from 'shared/helpers/timeHelper';
import CrmCardAiPanel from './CrmCardAiPanel.vue';
import CrmCardSummaryPanel from './CrmCardSummaryPanel.vue';
import CrmCardAutoFollowupStatus from './CrmCardAutoFollowupStatus.vue';
import WhatsappApiMessageTemplatesAPI from 'dashboard/api/whatsappApiMessageTemplates';
import MetaConversionsAPI from 'dashboard/api/metaConversions';
import { useCrmOrigin } from '../composables/useCrmOrigin';
import CrmCardPill from './CrmCardPill.vue';

const props = defineProps({
  show: { type: Boolean, default: false },
  mode: { type: String, default: 'create' },
  card: { type: Object, default: null },
  // Tab to land on when the drawer opens (e.g. 'followups' from the calendar
  // quick-add). Null → default 'summary'.
  initialTab: { type: String, default: null },
  stages: { type: Array, default: () => [] },
  pipelineId: { type: [String, Number], default: '' },
  agents: { type: Array, default: () => [] },
  inboxes: { type: Array, default: () => [] },
  followUps: { type: Array, default: () => [] },
  canManageCards: { type: Boolean, default: false },
  canManageAi: { type: Boolean, default: false },
  isSaving: { type: Boolean, default: false },
  isLoadingDetails: { type: Boolean, default: false },
  isArchiving: { type: Boolean, default: false },
  isFetchingFollowUps: { type: Boolean, default: false },
  isSavingFollowUp: { type: Boolean, default: false },
  meetingsEnabled: { type: Boolean, default: false },
});

const emit = defineEmits([
  'close',
  'save',
  'archive',
  'closeDeal',
  'createFollowUp',
  'completeFollowUp',
  'cancelFollowUp',
  'refreshCard',
  'scheduleMeeting',
]);

const { t } = useI18n();
const { originFromCampaigns, humanizedOriginLabel, formatOriginTitle } =
  useCrmOrigin();

const store = useStore();
const isCrmAiEnabled = computed(
  () =>
    store.getters['globalConfig/get']?.crmAiEnabled === true ||
    window.globalConfig?.CRM_AI_ENABLED === 'true'
);
const route = useRoute();
const router = useRouter();

const form = reactive({
  title: '',
  description: '',
  stageId: '',
  valueAmount: '',
  currency: 'BRL',
  priority: 'medium',
  score: 0,
  expectedCloseAt: '',
  ownerId: '',
  inboxId: '',
  contactId: '',
});
// Editable contact fields shown in the Contact tab. Native columns (name/email/
// phone) + Chatwoot-standard additional_attributes (company/city/country) +
// non-native custom_attributes (address/job title). Persisted via the existing
// contacts update API, which merges additional/custom attributes server-side.
const contactForm = reactive({
  name: '',
  email: '',
  phoneNumber: '',
  company: '',
  jobTitle: '',
  address: '',
  city: '',
  country: '',
});
const contactSnapshot = ref('');
const followUpForm = reactive({
  title: '',
  dueAt: '',
  automationMode: 'reminder_only',
  description: '',
  messageBody: '',
  whatsappApiTemplateId: '',
  nativeTemplateKey: '',
  templateName: '',
  templateLanguage: 'pt_BR',
  templateNamespace: '',
});
const followUpMessagingWindow = ref(null);
const isLoadingMessagingWindow = ref(false);
const whatsappApiTemplates = ref([]);
const isLoadingWhatsappTemplates = ref(false);

const contactSearch = ref('');
const contactResults = ref([]);
const hasSearchedContacts = ref(false);
const isSearchingContacts = ref(false);
const activeTab = ref('summary');

const isEditing = computed(() => props.mode === 'edit');
const panelTitle = computed(() => {
  if (!isEditing.value) return t('CRM_KANBAN.DRAWER.CREATE_TITLE');
  // Pull the card's own title into the header once it has one ("Detalhes do {nome}");
  // a brand-new/untitled card keeps the generic "Detalhes do card".
  const name = form.title?.trim();
  return name
    ? t('CRM_KANBAN.DRAWER.EDIT_TITLE_NAMED', { name })
    : t('CRM_KANBAN.DRAWER.EDIT_TITLE');
});
const panelSubtitle = computed(() =>
  isEditing.value
    ? t('CRM_KANBAN.DRAWER.EDIT_SUBTITLE')
    : t('CRM_KANBAN.DRAWER.CREATE_SUBTITLE')
);

const stageOptions = computed(() =>
  props.stages.map(stage => ({ value: stage.id, label: stage.name }))
);
const agentOptions = computed(() =>
  props.agents.map(agent => ({ value: agent.id, label: agent.name }))
);
const inboxOptions = computed(() =>
  props.inboxes.map(inbox => ({ value: inbox.id, label: inbox.name }))
);
const priorityOptions = computed(() => [
  { value: 'low', label: t('CRM_KANBAN.PRIORITY.LOW') },
  { value: 'medium', label: t('CRM_KANBAN.PRIORITY.MEDIUM') },
  { value: 'high', label: t('CRM_KANBAN.PRIORITY.HIGH') },
  { value: 'urgent', label: t('CRM_KANBAN.PRIORITY.URGENT') },
]);
const detailTabs = computed(() => [
  { id: 'summary', label: t('CRM_KANBAN.DRAWER.TAB_SUMMARY') },
  { id: 'contact', label: t('CRM_KANBAN.DRAWER.TAB_CONTACT') },
  { id: 'conversations', label: t('CRM_KANBAN.DRAWER.TAB_CONVERSATIONS') },
  { id: 'followups', label: t('CRM_KANBAN.DRAWER.TAB_FOLLOW_UPS') },
  { id: 'timeline', label: t('CRM_KANBAN.DRAWER.TAB_TIMELINE') },
]);
const selectedContact = computed(() =>
  contactResults.value.find(contact => contact.id === Number(form.contactId))
);
const linkedConversationDisplayId = computed(
  () => props.card?.conversation?.display_id || ''
);
const originPill = computed(() => originFromCampaigns(props.card?.campaigns));
const hasLinkedContext = computed(
  () =>
    isEditing.value &&
    (props.card?.contact ||
      props.card?.inbox ||
      linkedConversationDisplayId.value)
);
const linkedConversations = computed(() => {
  if (props.card?.linked_conversations?.length) {
    return props.card.linked_conversations;
  }
  if (props.card?.conversation) return [props.card.conversation];
  return [];
});
const activities = computed(() => props.card?.activities || []);
const linkedConversationId = computed(
  () => props.card?.conversation_id || props.card?.conversation?.id || ''
);
const canSnoozeConversation = computed(() =>
  Boolean(linkedConversationId.value)
);
const canAutoSendMessage = computed(() => Boolean(linkedConversationId.value));
const linkedInboxId = computed(
  () => props.card?.inbox_id || props.card?.inbox?.id || ''
);
const isWhatsappApiInbox = computed(
  () => followUpMessagingWindow.value?.whatsapp_api_inbox === true
);
const isWhatsappNativeInbox = computed(
  () => followUpMessagingWindow.value?.whatsapp_native_inbox === true
);
const requiresTemplateNow = computed(
  () => followUpMessagingWindow.value?.requires_template === true
);
const whatsappApiTemplateOptions = computed(() =>
  whatsappApiTemplates.value.map(template => ({
    value: template.id,
    label: template.name,
  }))
);
// Official WhatsApp inboxes reuse the native template engine: the already
// imported/approved templates for that inbox's number, sourced from the
// inboxes store getter (channel.message_templates). The custom path stays for
// Channel::Api campaign inboxes.
const nativeWhatsappTemplates = computed(() => {
  if (!isWhatsappNativeInbox.value || !linkedInboxId.value) return [];
  return (
    store.getters['inboxes/getFilteredWhatsAppTemplates'](
      linkedInboxId.value
    ) || []
  );
});
const nativeWhatsappTemplateOptions = computed(() =>
  nativeWhatsappTemplates.value.map(template => ({
    value: `${template.name}::${template.language}`,
    label: `${template.name} (${template.language})`,
  }))
);
const activeFollowUps = computed(() =>
  props.followUps.filter(
    followUp => followUp.status === 'pending' || followUp.status === 'overdue'
  )
);
// Done/canceled — shown collapsed at the bottom of the Follow-ups tab.
const completedFollowUps = computed(() =>
  props.followUps.filter(
    followUp => followUp.status !== 'pending' && followUp.status !== 'overdue'
  )
);
// --- Deal close (Win / Lose / Reopen) ---------------------------------------
const cardStatus = computed(() => props.card?.status || 'open');
const isDealOpen = computed(() => cardStatus.value === 'open');
const statusLabel = computed(() =>
  t(`CRM_KANBAN.DRAWER.STATUS_${String(cardStatus.value).toUpperCase()}`)
);
const statusPillClass = computed(
  () =>
    ({
      won: 'bg-n-teal-3 text-n-teal-11',
      lost: 'bg-n-ruby-3 text-n-ruby-11',
      archived: 'bg-n-slate-4 text-n-slate-10',
    })[cardStatus.value] || 'bg-n-blue-3 text-n-blue-11'
);
const aiFilledValue = computed(() => props.card?.ai_value?.source === 'ai');

// CTWA conversion sync-state for the open card (FE-5 badge). Read-only ledger row
// fetched when the drawer opens, reset on close/card change so no stale badge shows.
const cardId = computed(() => props.card?.id || '');
const metaConversion = ref(null);
const metaConversionPill = computed(() => {
  const pills = {
    accepted: {
      class: 'bg-n-teal-3 text-n-teal-11',
      label: 'CRM_KANBAN.META_SYNC_STATUS.CARD_SENT',
    },
    pending: {
      class: 'bg-n-amber-3 text-n-amber-11',
      label: 'CRM_KANBAN.META_SYNC_STATUS.LABEL_PENDING',
    },
    error: {
      class: 'bg-n-ruby-3 text-n-ruby-11',
      label: 'CRM_KANBAN.META_SYNC_STATUS.LABEL_ERROR',
    },
  };
  // 'skipped' or no row → no badge, keep the drawer uncluttered.
  return pills[metaConversion.value?.status] || null;
});

const showWinDialog = ref(false);
const showLoseDialog = ref(false);
const winAmount = ref('');
const winCurrency = ref('BRL');
const loseReason = ref('');

const openWinDialog = () => {
  winAmount.value = props.card?.value_cents
    ? Number(props.card.value_cents) / 100
    : '';
  winCurrency.value = props.card?.currency || 'BRL';
  showWinDialog.value = true;
};
const openLoseDialog = () => {
  loseReason.value = props.card?.lost_reason || '';
  showLoseDialog.value = true;
};
const confirmWin = () => {
  const amount = Number(winAmount.value);
  emit('closeDeal', {
    result: 'won',
    value_cents:
      Number.isFinite(amount) && amount > 0
        ? Math.round(amount * 100)
        : undefined,
    currency: winCurrency.value || 'BRL',
  });
  showWinDialog.value = false;
};
const confirmLose = () => {
  emit('closeDeal', {
    result: 'lost',
    lost_reason: loseReason.value || undefined,
  });
  showLoseDialog.value = false;
};
const reopenDeal = () => emit('closeDeal', { result: 'reopen' });

const hydrateContactForm = card => {
  const contact = card?.contact || {};
  const add = contact.additional_attributes || {};
  const custom = contact.custom_attributes || {};
  contactForm.name = contact.name || '';
  contactForm.email = contact.email || '';
  contactForm.phoneNumber = contact.phone_number || '';
  contactForm.company = add.company_name || '';
  contactForm.city = add.city || '';
  contactForm.country = add.country || '';
  contactForm.address = custom.address || '';
  contactForm.jobTitle = custom.job_title || '';
  contactSnapshot.value = JSON.stringify({ ...contactForm });
};

const resetForm = () => {
  const card = props.card || {};
  form.title = card.title || '';
  form.description = card.description || '';
  form.stageId = card.stage_id || props.stages[0]?.id || '';
  form.valueAmount = card.value_cents ? Number(card.value_cents) / 100 : '';
  form.currency = card.currency || 'BRL';
  form.priority = card.priority || 'medium';
  form.score = card.score || 0;
  form.expectedCloseAt = card.expected_close_at
    ? card.expected_close_at.slice(0, 10)
    : '';
  form.ownerId = card.owner_id || '';
  form.inboxId = card.inbox_id || '';
  form.contactId = card.contact_id || '';
  hydrateContactForm(card);
  contactSearch.value = card.contact?.name || '';
  contactResults.value = card.contact ? [card.contact] : [];
  hasSearchedContacts.value = false;
  activeTab.value = props.initialTab || 'summary';
  followUpForm.title = t('CRM_KANBAN.DRAWER.FOLLOW_UP_DEFAULT_TITLE');
  followUpForm.dueAt = '';
  followUpForm.automationMode = 'reminder_only';
  followUpForm.description = '';
  followUpForm.messageBody = '';
  followUpForm.whatsappApiTemplateId = '';
  followUpForm.nativeTemplateKey = '';
  followUpForm.templateName = '';
  followUpForm.templateLanguage = 'pt_BR';
  followUpForm.templateNamespace = '';
  followUpMessagingWindow.value = null;
  whatsappApiTemplates.value = [];
};

const loadFollowUpMessagingWindow = async () => {
  if (!linkedConversationId.value) {
    followUpMessagingWindow.value = null;
    return;
  }

  isLoadingMessagingWindow.value = true;
  try {
    const dueAtIso = followUpForm.dueAt
      ? new Date(followUpForm.dueAt).toISOString()
      : undefined;
    const response = await CrmKanbanAPI.getFollowUpMessagingWindow(
      linkedConversationId.value,
      dueAtIso
    );
    followUpMessagingWindow.value = response.data;
  } catch {
    followUpMessagingWindow.value = null;
  } finally {
    isLoadingMessagingWindow.value = false;
  }
};

const loadWhatsappApiTemplates = async () => {
  if (!linkedInboxId.value) {
    whatsappApiTemplates.value = [];
    return;
  }

  isLoadingWhatsappTemplates.value = true;
  try {
    const response = await WhatsappApiMessageTemplatesAPI.get(
      linkedInboxId.value
    );
    whatsappApiTemplates.value = response.data.payload || [];
  } catch {
    whatsappApiTemplates.value = [];
  } finally {
    isLoadingWhatsappTemplates.value = false;
  }
};

// Maps the chosen native template (name::language) back onto the metadata
// fields the backend MessageSender native path consumes (template_params).
const onNativeTemplateSelected = () => {
  const selected = nativeWhatsappTemplates.value.find(
    template =>
      `${template.name}::${template.language}` ===
      followUpForm.nativeTemplateKey
  );
  if (!selected) {
    followUpForm.templateName = '';
    followUpForm.templateLanguage = '';
    followUpForm.templateNamespace = '';
    return;
  }
  followUpForm.templateName = selected.name;
  followUpForm.templateLanguage = selected.language || 'pt_BR';
  followUpForm.templateNamespace = selected.namespace || '';
};

const searchContacts = async () => {
  if (contactSearch.value.trim().length < 2) return;
  isSearchingContacts.value = true;
  hasSearchedContacts.value = true;
  try {
    const response = await ContactAPI.search(contactSearch.value.trim(), 1);
    contactResults.value = response.data.payload || [];
  } finally {
    isSearchingContacts.value = false;
  }
};

const onContactSelected = () => {
  if (!selectedContact.value || form.title.trim()) return;
  form.title = selectedContact.value.name || selectedContact.value.phone_number;
};

// Reset when the drawer opens or the selected card object changes. We intentionally
// drop props.stages from the deps: realtime card events and the board poll rebuild
// board.stages into a new array reference on every update, and a busy board would
// re-run resetForm mid-edit, wiping the title/contact/follow-up fields being typed.
// props.card is kept because the parent only rebinds selectedCard on explicit flows
// (open, then shallow->detailed hydration) — never from realtime — so it does not
// churn and its change must still re-hydrate the form. Stage <select> options bind
// to props.stages directly, so they stay live without a reset.
watch(
  () => [props.show, props.card],
  () => {
    if (props.show) resetForm();
  },
  { immediate: true }
);

// Fetch the card's Meta conversion row whenever the drawer opens or switches card.
// Reset first so a stale badge never lingers; failures simply hide the badge. The
// requestedId guard drops slow responses that arrive after the card changed, and
// only the row matching THIS card is accepted (never another card's conversion).
const fetchMetaConversion = async () => {
  metaConversion.value = null;
  if (!props.show || !cardId.value) return;
  const requestedId = cardId.value;
  try {
    const { data } = await MetaConversionsAPI.getForCards([requestedId]);
    if (requestedId !== cardId.value) return;
    const payload = data?.payload || [];
    metaConversion.value =
      payload.find(row => Number(row.card_id) === Number(requestedId)) || null;
  } catch {
    if (requestedId === cardId.value) metaConversion.value = null;
  }
};
watch(() => [props.show, cardId.value], fetchMetaConversion, {
  immediate: true,
});

// Re-evaluate the messaging window whenever auto-send is selected OR the chosen
// due date changes: the window must be computed at dueAt, not at Time.current,
// so the template UI shows when the send will fall outside the 24h window.
const refreshMessagingWindow = async () => {
  if (
    followUpForm.automationMode !== 'auto_send_message' ||
    !linkedConversationId.value
  ) {
    return;
  }
  await loadFollowUpMessagingWindow();
  if (
    isWhatsappApiInbox.value &&
    followUpMessagingWindow.value?.requires_template
  ) {
    await loadWhatsappApiTemplates();
  }
};

watch(() => followUpForm.automationMode, refreshMessagingWindow);
watch(() => followUpForm.dueAt, refreshMessagingWindow);

const buildPayload = () => {
  const payload = {
    title: form.title.trim(),
    description: form.description.trim(),
    value_cents: form.valueAmount
      ? Math.round(Number(form.valueAmount) * 100)
      : 0,
    currency: form.currency || 'BRL',
    priority: form.priority,
    score: Number(form.score || 0),
    expected_close_at: form.expectedCloseAt || null,
  };

  if (!isEditing.value) {
    payload.stage_id = form.stageId;
    payload.pipeline_id = props.pipelineId;
    if (props.canManageCards && form.ownerId) payload.owner_id = form.ownerId;
    if (form.inboxId) payload.inbox_id = form.inboxId;
    if (form.contactId) payload.contact_id = form.contactId;
  }

  return payload;
};

const contactDirty = computed(
  () => JSON.stringify({ ...contactForm }) !== contactSnapshot.value
);

// Send ONLY the keys the drawer manages — the server shallow-merges additional/
// custom attributes, so every other key (incl. nested social_profiles) is preserved
// untouched. Avoids re-writing stale values for fields we don't edit here.
const buildContactPayload = () => ({
  name: contactForm.name.trim(),
  email: contactForm.email.trim(),
  phone_number: contactForm.phoneNumber.trim(),
  additional_attributes: {
    company_name: contactForm.company.trim(),
    city: contactForm.city.trim(),
    country: contactForm.country.trim(),
  },
  custom_attributes: {
    address: contactForm.address.trim(),
    job_title: contactForm.jobTitle.trim(),
  },
});

const persistContactIfChanged = async () => {
  const contact = props.card?.contact;
  if (!isEditing.value || !contact?.id || !contactDirty.value) return;

  await ContactAPI.update(contact.id, buildContactPayload());
};

const onSubmit = async () => {
  if (!form.title.trim() || (!isEditing.value && !form.stageId)) return;

  try {
    await persistContactIfChanged();
  } catch {
    useAlert(t('CRM_KANBAN.DRAWER.CONTACT_SAVE_ERROR'));
    return;
  }
  emit('save', buildPayload());
};

const buildAutoSendMetadata = () => {
  const metadata = {
    message_body: followUpForm.messageBody.trim(),
  };

  if (isWhatsappApiInbox.value && followUpForm.whatsappApiTemplateId) {
    metadata.whatsapp_api_message_template_id = Number(
      followUpForm.whatsappApiTemplateId
    );
  } else if (followUpForm.templateName.trim()) {
    metadata.template_name = followUpForm.templateName.trim();
    metadata.template_language =
      followUpForm.templateLanguage.trim() || 'pt_BR';
    if (followUpForm.templateNamespace.trim()) {
      metadata.template_namespace = followUpForm.templateNamespace.trim();
    }
  }

  return metadata;
};

const hasAutoSendTemplateFallback = () => {
  if (isWhatsappApiInbox.value) {
    return Boolean(followUpForm.whatsappApiTemplateId);
  }

  return (
    Boolean(followUpForm.templateName.trim()) &&
    Boolean(followUpForm.templateLanguage.trim())
  );
};

const resetFollowUpForm = () => {
  followUpForm.title = t('CRM_KANBAN.DRAWER.FOLLOW_UP_DEFAULT_TITLE');
  followUpForm.dueAt = '';
  followUpForm.automationMode = 'reminder_only';
  followUpForm.description = '';
  followUpForm.messageBody = '';
  followUpForm.whatsappApiTemplateId = '';
  followUpForm.nativeTemplateKey = '';
  followUpForm.templateName = '';
  followUpForm.templateLanguage = 'pt_BR';
  followUpForm.templateNamespace = '';
};

defineExpose({ resetFollowUpForm });

const createFollowUp = () => {
  if (!props.card?.id || !followUpForm.title.trim() || !followUpForm.dueAt) {
    return;
  }

  if (
    followUpForm.automationMode === 'auto_send_message' &&
    !followUpForm.messageBody.trim()
  ) {
    useAlert(t('CRM_KANBAN.ALERTS.FOLLOW_UP_MESSAGE_BODY_REQUIRED'));
    return;
  }

  if (
    followUpForm.automationMode === 'auto_send_message' &&
    requiresTemplateNow.value &&
    !hasAutoSendTemplateFallback()
  ) {
    useAlert(t('CRM_KANBAN.ALERTS.FOLLOW_UP_TEMPLATE_REQUIRED'));
    return;
  }

  const payload = {
    card_id: props.card.id,
    conversation_id: linkedConversationId.value || null,
    title: followUpForm.title.trim(),
    description: followUpForm.description.trim(),
    follow_up_type: 'task',
    automation_mode: followUpForm.automationMode,
    due_at: new Date(followUpForm.dueAt).toISOString(),
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone || 'UTC',
  };

  if (followUpForm.automationMode === 'auto_send_message') {
    payload.metadata = buildAutoSendMetadata();
  }

  emit('createFollowUp', payload);
};

const openConversationByDisplayId = displayId => {
  if (!displayId) return;
  router.push({
    name: 'inbox_conversation',
    params: {
      accountId: route.params.accountId,
      conversation_id: displayId,
    },
  });
};

const openConversation = () => {
  openConversationByDisplayId(linkedConversationDisplayId.value);
};

const formatDate = value => {
  if (!value) return t('CRM_KANBAN.DRAWER.EMPTY_VALUE');
  return new Intl.DateTimeFormat('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(value));
};

// Per-event-type metadata: i18n label key, lucide icon and a colour tone.
// Keyed on the actual backend Crm::Activity#event_type values.
const ACTIVITY_META = {
  create: { key: 'ACTIVITY_CREATE', icon: 'i-lucide-plus', tone: 'positive' },
  update: { key: 'ACTIVITY_UPDATE', icon: 'i-lucide-pencil', tone: 'neutral' },
  move: { key: 'ACTIVITY_MOVE', icon: 'i-lucide-arrow-right', tone: 'info' },
  won: { key: 'ACTIVITY_WON', icon: 'i-lucide-trophy', tone: 'positive' },
  lost: { key: 'ACTIVITY_LOST', icon: 'i-lucide-circle-x', tone: 'negative' },
  reopen: {
    key: 'ACTIVITY_REOPEN',
    icon: 'i-lucide-rotate-ccw',
    tone: 'neutral',
  },
  archive: { key: 'ACTIVITY_ARCHIVE', icon: 'i-lucide-archive', tone: 'muted' },
  conversation_linked: {
    key: 'ACTIVITY_LINK_CONVERSATION',
    icon: 'i-lucide-link',
    tone: 'info',
  },
  conversation_unlinked: {
    key: 'ACTIVITY_UNLINK_CONVERSATION',
    icon: 'i-lucide-unlink',
    tone: 'muted',
  },
  contact_linked: {
    key: 'ACTIVITY_LINK_CONTACT',
    icon: 'i-lucide-user-plus',
    tone: 'info',
  },
  contact_unlinked: {
    key: 'ACTIVITY_UNLINK_CONTACT',
    icon: 'i-lucide-user-minus',
    tone: 'muted',
  },
  conversation_sync: {
    key: 'ACTIVITY_CONVERSATION_SYNC',
    icon: 'i-lucide-refresh-cw',
    tone: 'neutral',
  },
  conversation_dedup_reuse: {
    key: 'ACTIVITY_CONVERSATION_DEDUP_REUSE',
    icon: 'i-lucide-layers',
    tone: 'neutral',
  },
  follow_up_created: {
    key: 'ACTIVITY_FOLLOW_UP_CREATED',
    icon: 'i-lucide-bell-plus',
    tone: 'info',
  },
  follow_up_updated: {
    key: 'ACTIVITY_FOLLOW_UP_UPDATED',
    icon: 'i-lucide-bell',
    tone: 'neutral',
  },
  follow_up_completed: {
    key: 'ACTIVITY_FOLLOW_UP_COMPLETED',
    icon: 'i-lucide-check',
    tone: 'positive',
  },
  follow_up_canceled: {
    key: 'ACTIVITY_FOLLOW_UP_CANCELED',
    icon: 'i-lucide-bell-off',
    tone: 'muted',
  },
  follow_up_overdue: {
    key: 'ACTIVITY_FOLLOW_UP_OVERDUE',
    icon: 'i-lucide-alarm-clock',
    tone: 'negative',
  },
  follow_up_message_sent: {
    key: 'ACTIVITY_FOLLOW_UP_MESSAGE_SENT',
    icon: 'i-lucide-send',
    tone: 'positive',
  },
  follow_up_message_failed: {
    key: 'ACTIVITY_FOLLOW_UP_MESSAGE_FAILED',
    icon: 'i-lucide-triangle-alert',
    tone: 'negative',
  },
  meeting_scheduled: {
    key: 'ACTIVITY_MEETING_SCHEDULED',
    icon: 'i-lucide-video',
    tone: 'info',
  },
  meeting_rescheduled: {
    key: 'ACTIVITY_MEETING_RESCHEDULED',
    icon: 'i-lucide-calendar-clock',
    tone: 'info',
  },
  meeting_canceled: {
    key: 'ACTIVITY_MEETING_CANCELED',
    icon: 'i-lucide-calendar-x',
    tone: 'negative',
  },
  meeting_outcome_recorded: {
    key: 'ACTIVITY_MEETING_OUTCOME',
    icon: 'i-lucide-circle-check',
    tone: 'info',
  },
  automation_owner_assigned: {
    key: 'ACTIVITY_AUTOMATION_OWNER_ASSIGNED',
    icon: 'i-lucide-user-check',
    tone: 'info',
  },
  automation_stage_moved: {
    key: 'ACTIVITY_AUTOMATION_STAGE_MOVED',
    icon: 'i-lucide-arrow-right',
    tone: 'info',
  },
  automation_follow_up_created: {
    key: 'ACTIVITY_AUTOMATION_FOLLOW_UP_CREATED',
    icon: 'i-lucide-bell-plus',
    tone: 'info',
  },
  ai_auto_moved: {
    key: 'ACTIVITY_AI_AUTO_MOVED',
    icon: 'i-lucide-sparkles',
    tone: 'info',
  },
  ai_suggested: {
    key: 'ACTIVITY_AI_SUGGESTED',
    icon: 'i-lucide-lightbulb',
    tone: 'info',
  },
  ai_dismissed: {
    key: 'ACTIVITY_AI_DISMISSED',
    icon: 'i-lucide-x',
    tone: 'muted',
  },
  ai_handoff: {
    key: 'ACTIVITY_AI_HANDOFF',
    icon: 'i-lucide-user-round-check',
    tone: 'info',
  },
  // Fase D: handoff do agente nativo Autonom.ia. Reusa o mesmo visual do handoff
  // do Kanban; o detalhe nunca expõe motivo bruto do LLM (payload só ids/strategy).
  autonomia_handoff: {
    key: 'ACTIVITY_AUTONOMIA_HANDOFF',
    icon: 'i-lucide-user-round-check',
    tone: 'info',
  },
};

const FALLBACK_META = { icon: 'i-lucide-history', tone: 'neutral' };

const ACTIVITY_TONE_CLASSES = {
  positive: 'bg-n-teal-3 text-n-teal-11',
  negative: 'bg-n-ruby-3 text-n-ruby-11',
  info: 'bg-n-blue-3 text-n-blue-11',
  neutral: 'bg-n-alpha-2 text-n-slate-11',
  muted: 'bg-n-slate-4 text-n-slate-10',
};

// AI work runs as a system actor (actor_type === 'system'). ai_dismissed is a
// human action (actor_type === 'user'), so it is NOT keyed on the 'ai_' prefix.
const activityActor = activity => {
  if (activity.actor_type === 'system') {
    return activity.event_type?.startsWith('ai_')
      ? t('CRM_KANBAN.DRAWER.AI_ACTOR')
      : t('CRM_KANBAN.DRAWER.SYSTEM_ACTOR');
  }
  return activity.actor_name || t('CRM_KANBAN.DRAWER.UNKNOWN_ACTOR');
};

// Returns the readable label for an id-bearing payload key, preferring the
// backend-provided labels{} map and falling back to a "#id" reference.
const activityLabelValue = (activity, key) => {
  const labels = activity.labels || {};
  if (labels[key]) return labels[key];
  const raw = activity.payload?.[key];
  return raw ? `#${raw}` : '';
};

// Builds a friendly one-line description for the activity. Returns '' when the
// event type has no extra detail worth rendering.
const activityDetail = activity => {
  switch (activity.event_type) {
    case 'move':
    case 'ai_auto_moved':
    case 'ai_suggested': {
      const from = activityLabelValue(activity, 'from_stage_id');
      const to = activityLabelValue(activity, 'to_stage_id');
      if (from && to)
        return t('CRM_KANBAN.DRAWER.ACTIVITY_DETAIL_STAGE_CHANGE', {
          from,
          to,
        });
      if (to) return t('CRM_KANBAN.DRAWER.ACTIVITY_DETAIL_STAGE_TO', { to });
      return '';
    }
    case 'automation_stage_moved': {
      const to = activityLabelValue(activity, 'target_stage_id');
      return to ? t('CRM_KANBAN.DRAWER.ACTIVITY_DETAIL_STAGE_TO', { to }) : '';
    }
    case 'automation_owner_assigned': {
      const owner = activityLabelValue(activity, 'owner_id');
      return owner
        ? t('CRM_KANBAN.DRAWER.ACTIVITY_DETAIL_OWNER', { owner })
        : '';
    }
    case 'ai_handoff': {
      const agent = activityLabelValue(activity, 'assignee_id');
      const reason = activity.payload?.reason;
      if (agent && reason)
        return t('CRM_KANBAN.DRAWER.ACTIVITY_DETAIL_HANDOFF_REASON', {
          agent,
          reason,
        });
      if (agent)
        return t('CRM_KANBAN.DRAWER.ACTIVITY_DETAIL_HANDOFF', { agent });
      return reason || '';
    }
    // Fase D: handoff do agente nativo. Mostra só o destino (membro do inbox ou
    // time); nunca há `reason` no payload (IP oculto).
    case 'autonomia_handoff': {
      const assignee = activityLabelValue(activity, 'assignee_id');
      if (assignee)
        return t('CRM_KANBAN.DRAWER.ACTIVITY_DETAIL_HANDOFF', {
          agent: assignee,
        });
      const team = activityLabelValue(activity, 'team_id');
      return team
        ? t('CRM_KANBAN.DRAWER.ACTIVITY_DETAIL_AUTONOMIA_HANDOFF_TEAM', {
            team,
          })
        : '';
    }
    case 'contact_linked':
    case 'contact_unlinked': {
      const contact = activityLabelValue(activity, 'contact_id');
      return contact
        ? t('CRM_KANBAN.DRAWER.ACTIVITY_DETAIL_CONTACT', { contact })
        : '';
    }
    case 'follow_up_created':
    case 'follow_up_updated':
    case 'follow_up_completed':
    case 'follow_up_canceled':
    case 'follow_up_overdue':
    case 'follow_up_message_sent':
    case 'follow_up_message_failed': {
      const title = activity.payload?.title;
      return title || '';
    }
    case 'meeting_scheduled':
    case 'meeting_rescheduled':
    case 'meeting_canceled': {
      const title = activity.payload?.title;
      return title
        ? t('CRM_KANBAN.DRAWER.ACTIVITY_DETAIL_MEETING', { title })
        : '';
    }
    default:
      return '';
  }
};

// Single source of truth for rendering a timeline entry. Hard non-JSON
// fallback: unknown event types still produce a humanized label + icon.
const describeActivity = activity => {
  const meta = ACTIVITY_META[activity.event_type] || FALLBACK_META;
  const title = meta.key
    ? t(`CRM_KANBAN.DRAWER.${meta.key}`)
    : t('CRM_KANBAN.DRAWER.ACTIVITY_GENERIC');
  return {
    title,
    icon: meta.icon,
    toneClass:
      ACTIVITY_TONE_CLASSES[meta.tone] || ACTIVITY_TONE_CLASSES.neutral,
    actor: activityActor(activity),
    detail: activityDetail(activity),
    relativeTime: relativeTimeFromISO(activity.created_at),
  };
};

const timelineEntries = computed(() =>
  activities.value.map(activity => ({
    id: activity.id,
    ...describeActivity(activity),
  }))
);

const followUpStatusClass = followUp => {
  const map = {
    pending: 'bg-n-teal-3 text-n-teal-11',
    overdue: 'bg-n-ruby-3 text-n-ruby-11',
    done: 'bg-n-slate-4 text-n-slate-11',
    canceled: 'bg-n-slate-4 text-n-slate-10',
  };
  return map[followUp.status] || map.pending;
};

const followUpStatusLabel = followUp => {
  const map = {
    pending: t('CRM_KANBAN.FOLLOW_UP_STATUS.PENDING'),
    overdue: t('CRM_KANBAN.FOLLOW_UP_STATUS.OVERDUE'),
    done: t('CRM_KANBAN.FOLLOW_UP_STATUS.DONE'),
    canceled: t('CRM_KANBAN.FOLLOW_UP_STATUS.CANCELED'),
  };
  return map[followUp.status] || followUp.status;
};

const followUpAutomationLabel = followUp => {
  const map = {
    reminder_only: t('CRM_KANBAN.FOLLOW_UP_MODE.REMINDER_ONLY'),
    snooze_conversation: t('CRM_KANBAN.FOLLOW_UP_MODE.SNOOZE_CONVERSATION'),
    auto_send_message: t('CRM_KANBAN.FOLLOW_UP_MODE.AUTO_SEND_MESSAGE'),
  };
  return map[followUp.automation_mode] || followUp.automation_mode;
};

useKeyboardEvents({
  Escape: {
    action: () => {
      if (props.show) emit('close');
    },
    allowOnFocusedInput: true,
  },
});
</script>

<template>
  <transition
    enter-active-class="transition duration-200 ease-out"
    enter-from-class="ltr:translate-x-full rtl:-translate-x-full opacity-0"
    leave-active-class="transition duration-150 ease-in"
    leave-to-class="ltr:translate-x-[30%] rtl:-translate-x-[30%] opacity-0"
  >
    <div
      v-if="show"
      class="fixed inset-y-0 ltr:right-0 rtl:left-0 z-50 flex h-full w-[34rem] max-w-full flex-col overflow-hidden border-n-weak bg-n-surface-2 shadow-lg ltr:border-l rtl:border-r"
    >
      <div
        class="flex items-start justify-between gap-4 border-b border-n-weak px-6 py-5"
      >
        <div class="min-w-0">
          <h2 class="mb-1 text-lg font-medium text-n-slate-12">
            {{ panelTitle }}
          </h2>
          <p class="mb-0 text-sm leading-5 text-n-slate-11">
            {{ panelSubtitle }}
          </p>
        </div>
        <Button icon="i-lucide-x" slate ghost sm @click="$emit('close')" />
      </div>

      <div class="flex-1 overflow-y-auto px-6 py-5">
        <div
          v-if="isEditing && canManageCards"
          class="flex flex-wrap items-center justify-between gap-3 p-3 mb-5 border rounded-lg border-n-weak bg-n-solid-1"
        >
          <span
            class="px-2 py-1 text-xs font-medium rounded-md"
            :class="statusPillClass"
          >
            {{ statusLabel }}
          </span>
          <div class="flex items-center gap-2">
            <template v-if="isDealOpen">
              <Button
                sm
                teal
                faded
                icon="i-lucide-trophy"
                :label="t('CRM_KANBAN.DRAWER.WIN_DEAL')"
                @click="openWinDialog"
              />
              <Button
                sm
                ruby
                faded
                icon="i-lucide-circle-x"
                :label="t('CRM_KANBAN.DRAWER.LOSE_DEAL')"
                @click="openLoseDialog"
              />
            </template>
            <Button
              v-else
              sm
              slate
              faded
              icon="i-lucide-rotate-ccw"
              :label="t('CRM_KANBAN.DRAWER.REOPEN_DEAL')"
              @click="reopenDeal"
            />
          </div>
        </div>
        <div
          v-if="metaConversionPill"
          class="flex flex-wrap items-center gap-2 mb-5"
        >
          <span class="text-xs font-medium text-n-slate-11">
            {{ t('CRM_KANBAN.META_SYNC_STATUS.CARD_TITLE') }}
          </span>
          <span
            class="px-2 py-1 text-xs font-medium rounded-md"
            :class="metaConversionPill.class"
          >
            {{ t(metaConversionPill.label) }}
          </span>
          <span
            v-if="metaConversion?.event_type"
            class="w-full text-xs text-n-slate-10"
          >
            {{
              t('CRM_KANBAN.META_SYNC_STATUS.CARD_EVENT', {
                event: metaConversion.event_type,
              })
            }}
          </span>
        </div>
        <div v-if="isEditing" class="mb-5 grid gap-3">
          <div
            class="flex gap-1 overflow-x-auto rounded-lg bg-n-alpha-black2 p-1"
          >
            <button
              v-for="tab in detailTabs"
              :key="tab.id"
              type="button"
              class="h-9 min-w-24 shrink-0 truncate rounded-md px-2 text-xs font-medium text-n-slate-11 transition-colors hover:bg-n-alpha-2 hover:text-n-slate-12"
              :class="
                activeTab === tab.id
                  ? 'bg-n-surface-2 text-n-slate-12 shadow-sm'
                  : ''
              "
              @click="activeTab = tab.id"
            >
              {{ tab.label }}
            </button>
          </div>
          <div
            v-if="isLoadingDetails"
            class="flex items-center gap-2 text-xs text-n-slate-10"
          >
            <span class="i-lucide-loader-2 size-3 animate-spin" />
            {{ t('CRM_KANBAN.DRAWER.LOADING_DETAILS') }}
          </div>
        </div>

        <div v-if="!isEditing || activeTab === 'summary'" class="grid gap-4">
          <Input
            v-model="form.title"
            :label="t('CRM_KANBAN.DRAWER.TITLE_LABEL')"
            :placeholder="t('CRM_KANBAN.DRAWER.TITLE_PLACEHOLDER')"
            :message="!form.title.trim() ? t('CRM_KANBAN.DRAWER.REQUIRED') : ''"
            :message-type="!form.title.trim() ? 'error' : 'info'"
          />

          <label class="grid gap-1">
            <span class="text-heading-3 text-n-slate-12">
              {{ t('CRM_KANBAN.DRAWER.DESCRIPTION_LABEL') }}
            </span>
            <textarea
              v-model="form.description"
              rows="4"
              class="reset-base !mb-0 w-full rounded-lg border-0 bg-n-alpha-black2 px-3 py-2.5 text-sm text-n-slate-12 outline outline-1 outline-n-weak transition-all placeholder:text-n-slate-10 focus:outline-n-brand"
              :placeholder="t('CRM_KANBAN.DRAWER.DESCRIPTION_PLACEHOLDER')"
            />
          </label>

          <CrmCardAiPanel
            v-if="isEditing && card?.id && isCrmAiEnabled"
            :card-id="card.id"
            :initial-suggestion="card.ai_suggestion"
            :can-manage-ai="canManageAi"
          />

          <section
            v-if="hasLinkedContext"
            class="grid gap-3 rounded-lg border border-n-weak bg-n-alpha-black2 p-3"
          >
            <div class="flex items-start justify-between gap-3">
              <div class="min-w-0">
                <p class="mb-1 text-sm font-medium text-n-slate-12">
                  {{ t('CRM_KANBAN.DRAWER.LINKS_TITLE') }}
                </p>
                <p class="mb-0 text-xs leading-5 text-n-slate-11">
                  {{ t('CRM_KANBAN.DRAWER.LINKS_HELP') }}
                </p>
              </div>
              <Button
                v-if="linkedConversationDisplayId"
                :label="t('CRM_KANBAN.DRAWER.OPEN_CONVERSATION')"
                icon="i-lucide-message-circle"
                slate
                faded
                sm
                @click="openConversation"
              />
            </div>

            <div v-if="originPill" class="flex min-w-0 items-center">
              <CrmCardPill
                :icon="originPill.icon"
                tone="teal"
                :title="formatOriginTitle(originPill)"
              >
                {{ humanizedOriginLabel(originPill) }}
                <template v-if="originPill.extraCount > 0" #trail>
                  <span class="shrink-0 font-semibold">
                    {{ `+${originPill.extraCount}` }}
                  </span>
                </template>
              </CrmCardPill>
            </div>

            <div class="grid gap-2 text-sm">
              <div
                v-if="card?.contact"
                class="flex min-w-0 items-center justify-between gap-3 rounded-md bg-n-alpha-black2 px-3 py-2"
              >
                <span class="text-n-slate-11">
                  {{ t('CRM_KANBAN.DRAWER.CONTACT') }}
                </span>
                <span class="truncate text-right text-n-slate-12">
                  {{ card.contact.name || card.contact.phone_number }}
                </span>
              </div>
              <div
                v-if="card?.inbox"
                class="flex min-w-0 items-center justify-between gap-3 rounded-md bg-n-alpha-black2 px-3 py-2"
              >
                <span class="text-n-slate-11">
                  {{ t('CRM_KANBAN.DRAWER.INBOX') }}
                </span>
                <span class="truncate text-right text-n-slate-12">
                  {{ card.inbox.name }}
                </span>
              </div>
              <div
                v-if="linkedConversationDisplayId"
                class="flex min-w-0 items-center justify-between gap-3 rounded-md bg-n-alpha-black2 px-3 py-2"
              >
                <span class="text-n-slate-11">
                  {{ t('CRM_KANBAN.DRAWER.CONVERSATION') }}
                </span>
                <span class="truncate text-right text-n-slate-12">
                  {{
                    t('CRM_KANBAN.DRAWER.CONVERSATION_NUMBER', {
                      id: linkedConversationDisplayId,
                    })
                  }}
                </span>
              </div>
            </div>
          </section>

          <section
            v-if="!isEditing"
            class="grid gap-3 rounded-lg border border-n-weak bg-n-alpha-black2 p-3"
          >
            <div>
              <p class="mb-1 text-sm font-medium text-n-slate-12">
                {{ t('CRM_KANBAN.DRAWER.MANUAL_CARD_TITLE') }}
              </p>
              <p class="mb-0 text-xs leading-5 text-n-slate-11">
                {{ t('CRM_KANBAN.DRAWER.MANUAL_CARD_HELP') }}
              </p>
            </div>

            <div class="grid gap-2 md:grid-cols-[1fr_auto]">
              <Input
                v-model="contactSearch"
                :label="t('CRM_KANBAN.DRAWER.CONTACT_SEARCH')"
                :placeholder="t('CRM_KANBAN.DRAWER.CONTACT_SEARCH_PLACEHOLDER')"
                @enter="searchContacts"
              />
              <div class="flex items-end">
                <Button
                  :label="t('CRM_KANBAN.DRAWER.CONTACT_SEARCH_BUTTON')"
                  icon="i-lucide-search"
                  slate
                  faded
                  :is-loading="isSearchingContacts"
                  :disabled="contactSearch.trim().length < 2"
                  @click="searchContacts"
                />
              </div>
            </div>

            <label v-if="contactResults.length" class="grid gap-1">
              <span class="text-heading-3 text-n-slate-12">
                {{ t('CRM_KANBAN.DRAWER.CONTACT') }}
              </span>
              <select
                v-model="form.contactId"
                class="reset-base !mb-0 h-10 w-full rounded-lg border-0 bg-n-alpha-black2 px-3 text-sm text-n-slate-12 outline outline-1 outline-n-weak focus:outline-n-brand"
                @change="onContactSelected"
              >
                <option value="">
                  {{ t('CRM_KANBAN.DRAWER.NO_CONTACT') }}
                </option>
                <option
                  v-for="contact in contactResults"
                  :key="contact.id"
                  :value="contact.id"
                >
                  {{ contact.name || contact.phone_number }}
                </option>
              </select>
            </label>

            <p
              v-else-if="hasSearchedContacts && !isSearchingContacts"
              class="mb-0 text-xs text-n-slate-10"
            >
              {{ t('CRM_KANBAN.DRAWER.CONTACT_EMPTY') }}
            </p>
          </section>

          <label v-if="!isEditing" class="grid gap-1">
            <span class="text-heading-3 text-n-slate-12">
              {{ t('CRM_KANBAN.DRAWER.STAGE') }}
            </span>
            <select
              v-model="form.stageId"
              class="reset-base !mb-0 h-10 w-full rounded-lg border-0 bg-n-alpha-black2 px-3 text-sm text-n-slate-12 outline outline-1 outline-n-weak focus:outline-n-brand"
            >
              <option
                v-for="stage in stageOptions"
                :key="stage.value"
                :value="stage.value"
              >
                {{ stage.label }}
              </option>
            </select>
          </label>

          <div class="grid grid-cols-2 gap-3">
            <Input
              v-model="form.valueAmount"
              type="number"
              min="0"
              :label="t('CRM_KANBAN.DRAWER.VALUE')"
              :placeholder="t('CRM_KANBAN.DRAWER.VALUE_PLACEHOLDER')"
            />
            <Input
              v-model="form.score"
              type="number"
              min="0"
              max="100"
              :label="t('CRM_KANBAN.DRAWER.SCORE')"
              :placeholder="t('CRM_KANBAN.DRAWER.SCORE_PLACEHOLDER')"
            />
          </div>

          <div class="grid grid-cols-2 gap-3">
            <label class="grid gap-1">
              <span class="text-heading-3 text-n-slate-12">
                {{ t('CRM_KANBAN.DRAWER.PRIORITY') }}
              </span>
              <select
                v-model="form.priority"
                class="reset-base !mb-0 h-10 w-full rounded-lg border-0 bg-n-alpha-black2 px-3 text-sm text-n-slate-12 outline outline-1 outline-n-weak focus:outline-n-brand"
              >
                <option
                  v-for="priority in priorityOptions"
                  :key="priority.value"
                  :value="priority.value"
                >
                  {{ priority.label }}
                </option>
              </select>
            </label>
            <Input
              v-model="form.expectedCloseAt"
              type="date"
              :label="t('CRM_KANBAN.DRAWER.EXPECTED_CLOSE_AT')"
            />
          </div>

          <label v-if="!isEditing && inboxOptions.length" class="grid gap-1">
            <span class="text-heading-3 text-n-slate-12">
              {{ t('CRM_KANBAN.DRAWER.INBOX') }}
            </span>
            <select
              v-model="form.inboxId"
              class="reset-base !mb-0 h-10 w-full rounded-lg border-0 bg-n-alpha-black2 px-3 text-sm text-n-slate-12 outline outline-1 outline-n-weak focus:outline-n-brand"
            >
              <option value="">
                {{ t('CRM_KANBAN.DRAWER.NO_INBOX') }}
              </option>
              <option
                v-for="inbox in inboxOptions"
                :key="inbox.value"
                :value="inbox.value"
              >
                {{ inbox.label }}
              </option>
            </select>
          </label>

          <label
            v-if="!isEditing && canManageCards && agentOptions.length"
            class="grid gap-1"
          >
            <span class="text-heading-3 text-n-slate-12">
              {{ t('CRM_KANBAN.DRAWER.OWNER') }}
            </span>
            <select
              v-model="form.ownerId"
              class="reset-base !mb-0 h-10 w-full rounded-lg border-0 bg-n-alpha-black2 px-3 text-sm text-n-slate-12 outline outline-1 outline-n-weak focus:outline-n-brand"
            >
              <option value="">
                {{ t('CRM_KANBAN.DRAWER.USE_CURRENT_USER') }}
              </option>
              <option
                v-for="agent in agentOptions"
                :key="agent.value"
                :value="agent.value"
              >
                {{ agent.label }}
              </option>
            </select>
          </label>
        </div>

        <section v-else-if="activeTab === 'contact'" class="grid gap-4">
          <div
            v-if="card?.contact"
            class="grid gap-3 rounded-lg border border-n-weak bg-n-alpha-black2 p-4 md:grid-cols-2"
          >
            <Input
              v-model="contactForm.name"
              :label="t('CRM_KANBAN.DRAWER.CONTACT_NAME')"
              class="md:col-span-2"
            />
            <Input
              v-model="contactForm.email"
              :label="t('CRM_KANBAN.DRAWER.CONTACT_EMAIL')"
            />
            <label class="grid gap-1">
              <span class="text-xs font-medium text-n-slate-11">
                {{ t('CRM_KANBAN.DRAWER.CONTACT_PHONE') }}
              </span>
              <!-- Country selector + libphonenumber => always emits E.164 (+digits),
                   which the contact model requires for messaging. -->
              <PhoneNumberInput v-model="contactForm.phoneNumber" />
            </label>
            <Input
              v-model="contactForm.company"
              :label="t('CRM_KANBAN.DRAWER.CONTACT_COMPANY')"
            />
            <Input
              v-model="contactForm.jobTitle"
              :label="t('CRM_KANBAN.DRAWER.CONTACT_JOB_TITLE')"
            />
            <Input
              v-model="contactForm.address"
              :label="t('CRM_KANBAN.DRAWER.CONTACT_ADDRESS')"
              class="md:col-span-2"
            />
            <Input
              v-model="contactForm.city"
              :label="t('CRM_KANBAN.DRAWER.CONTACT_CITY')"
            />
            <Input
              v-model="contactForm.country"
              :label="t('CRM_KANBAN.DRAWER.CONTACT_COUNTRY')"
            />
            <p class="mb-0 text-xs leading-5 text-n-slate-11 md:col-span-2">
              {{ t('CRM_KANBAN.DRAWER.CONTACT_EDIT_HINT') }}
            </p>
          </div>
          <div
            v-else
            class="rounded-lg border border-dashed border-n-weak px-4 py-8 text-center"
          >
            <p class="mb-1 text-sm font-medium text-n-slate-12">
              {{ t('CRM_KANBAN.DRAWER.NO_CONTACT_TITLE') }}
            </p>
            <p class="mb-0 text-xs leading-5 text-n-slate-11">
              {{ t('CRM_KANBAN.DRAWER.NO_CONTACT_HELP') }}
            </p>
          </div>
        </section>

        <section v-else-if="activeTab === 'conversations'" class="grid gap-3">
          <CrmCardSummaryPanel
            v-if="isEditing && card?.id && isCrmAiEnabled"
            :card="card"
            :detail-loaded="!isLoadingDetails"
            :can-manage-ai="canManageAi"
            :ai-enabled="isCrmAiEnabled"
          />

          <article
            v-for="conversation in linkedConversations"
            :key="conversation.id || conversation.display_id"
            class="grid gap-3 rounded-lg border border-n-weak bg-n-alpha-black2 p-4"
          >
            <div class="flex items-start justify-between gap-3">
              <div class="min-w-0">
                <p class="mb-1 text-sm font-medium text-n-slate-12">
                  {{
                    t('CRM_KANBAN.DRAWER.CONVERSATION_NUMBER', {
                      id: conversation.display_id,
                    })
                  }}
                </p>
                <p class="mb-0 truncate text-xs text-n-slate-11">
                  {{
                    conversation.inbox_name ||
                    conversation.inbox?.name ||
                    t('CRM_KANBAN.DRAWER.NO_INBOX')
                  }}
                </p>
              </div>
              <Button
                :label="t('CRM_KANBAN.DRAWER.OPEN_CONVERSATION')"
                icon="i-lucide-message-circle"
                slate
                faded
                sm
                @click="openConversationByDisplayId(conversation.display_id)"
              />
            </div>
            <div class="grid grid-cols-2 gap-2 text-xs text-n-slate-11">
              <div>
                {{ t('CRM_KANBAN.DRAWER.CONVERSATION_STATUS') }}
                <span class="text-n-slate-12">{{ conversation.status }}</span>
              </div>
              <div>
                {{ t('CRM_KANBAN.DRAWER.CONVERSATION_LAST_ACTIVITY') }}
                <span class="text-n-slate-12">
                  {{ formatDate(conversation.last_activity_at) }}
                </span>
              </div>
              <div v-if="conversation.assignee_name" class="col-span-2">
                {{ t('CRM_KANBAN.DRAWER.CONVERSATION_ASSIGNEE') }}
                <span class="text-n-slate-12">
                  {{ conversation.assignee_name }}
                </span>
              </div>
            </div>
          </article>

          <div
            v-if="linkedConversations.length === 0"
            class="rounded-lg border border-dashed border-n-weak px-4 py-8 text-center"
          >
            <p class="mb-1 text-sm font-medium text-n-slate-12">
              {{ t('CRM_KANBAN.DRAWER.NO_CONVERSATIONS_TITLE') }}
            </p>
            <p class="mb-0 text-xs leading-5 text-n-slate-11">
              {{ t('CRM_KANBAN.DRAWER.NO_CONVERSATIONS_HELP') }}
            </p>
          </div>
        </section>

        <section v-else-if="activeTab === 'followups'" class="grid gap-4">
          <!-- 1) Open follow-ups (pending / overdue) on top -->
          <div
            v-if="isFetchingFollowUps"
            class="flex items-center gap-2 text-xs text-n-slate-10"
          >
            <span class="i-lucide-loader-2 size-3 animate-spin" />
            {{ t('CRM_KANBAN.DRAWER.FOLLOW_UP_LOADING') }}
          </div>
          <article
            v-for="followUp in activeFollowUps"
            :key="`active-${followUp.id}`"
            class="grid gap-3 rounded-lg border border-n-weak bg-n-alpha-black2 p-4"
          >
            <div class="flex items-start justify-between gap-3">
              <div class="min-w-0">
                <p class="mb-1 truncate text-sm font-medium text-n-slate-12">
                  {{ followUp.title }}
                </p>
                <p class="mb-0 flex flex-wrap gap-2 text-xs text-n-slate-11">
                  <span>{{ formatDate(followUp.due_at) }}</span>
                  <span>{{ followUpAutomationLabel(followUp) }}</span>
                </p>
              </div>
              <span
                class="shrink-0 rounded-md px-2 py-1 text-[11px] font-medium"
                :class="followUpStatusClass(followUp)"
              >
                {{ followUpStatusLabel(followUp) }}
              </span>
            </div>
            <p
              v-if="followUp.description"
              class="mb-0 text-xs leading-5 text-n-slate-11"
            >
              {{ followUp.description }}
            </p>
            <div class="flex justify-end gap-2">
              <Button
                :label="t('CRM_KANBAN.DRAWER.FOLLOW_UP_COMPLETE')"
                icon="i-lucide-check"
                slate
                faded
                sm
                :is-loading="isSavingFollowUp"
                @click="$emit('completeFollowUp', followUp)"
              />
              <Button
                :label="t('CRM_KANBAN.DRAWER.FOLLOW_UP_CANCEL')"
                icon="i-lucide-x"
                ruby
                ghost
                sm
                :is-loading="isSavingFollowUp"
                @click="$emit('cancelFollowUp', followUp)"
              />
            </div>
          </article>

          <!-- 2) New follow-up -->
          <div
            class="grid gap-3 rounded-lg border border-n-weak bg-n-alpha-black2 p-4"
          >
            <div>
              <p class="mb-1 text-sm font-medium text-n-slate-12">
                {{ t('CRM_KANBAN.DRAWER.FOLLOW_UP_CREATE_TITLE') }}
              </p>
              <p class="mb-0 text-xs leading-5 text-n-slate-11">
                {{ t('CRM_KANBAN.DRAWER.FOLLOW_UP_CREATE_HELP') }}
              </p>
            </div>

            <Input
              v-model="followUpForm.title"
              :label="t('CRM_KANBAN.DRAWER.FOLLOW_UP_TITLE')"
              :placeholder="t('CRM_KANBAN.DRAWER.FOLLOW_UP_TITLE_PLACEHOLDER')"
            />

            <label class="grid gap-1">
              <span class="text-heading-3 text-n-slate-12">
                {{ t('CRM_KANBAN.DRAWER.FOLLOW_UP_DUE_AT') }}
              </span>
              <input
                v-model="followUpForm.dueAt"
                type="datetime-local"
                class="reset-base !mb-0 h-10 w-full rounded-lg border-0 bg-n-alpha-black2 px-3 text-sm text-n-slate-12 outline outline-1 outline-n-weak focus:outline-n-brand"
              />
            </label>

            <label class="grid gap-1">
              <span class="text-heading-3 text-n-slate-12">
                {{ t('CRM_KANBAN.DRAWER.FOLLOW_UP_MODE') }}
              </span>
              <select
                v-model="followUpForm.automationMode"
                class="reset-base !mb-0 h-10 w-full rounded-lg border-0 bg-n-alpha-black2 px-3 text-sm text-n-slate-12 outline outline-1 outline-n-weak focus:outline-n-brand"
              >
                <option value="reminder_only">
                  {{ t('CRM_KANBAN.FOLLOW_UP_MODE.REMINDER_ONLY') }}
                </option>
                <option
                  value="snooze_conversation"
                  :disabled="!canSnoozeConversation"
                >
                  {{ t('CRM_KANBAN.FOLLOW_UP_MODE.SNOOZE_CONVERSATION') }}
                </option>
                <option
                  value="auto_send_message"
                  :disabled="!canAutoSendMessage"
                >
                  {{ t('CRM_KANBAN.FOLLOW_UP_MODE.AUTO_SEND_MESSAGE') }}
                </option>
              </select>
              <span
                v-if="!canSnoozeConversation"
                class="text-xs text-n-slate-10"
              >
                {{ t('CRM_KANBAN.DRAWER.FOLLOW_UP_SNOOZE_DISABLED') }}
              </span>
              <span v-if="!canAutoSendMessage" class="text-xs text-n-slate-10">
                {{ t('CRM_KANBAN.DRAWER.FOLLOW_UP_AUTO_SEND_DISABLED') }}
              </span>
            </label>

            <div
              v-if="followUpForm.automationMode === 'auto_send_message'"
              class="grid gap-3 rounded-lg border border-n-weak bg-n-alpha-black2 p-3"
            >
              <p class="mb-0 text-xs leading-5 text-n-slate-11">
                {{ t('CRM_KANBAN.DRAWER.FOLLOW_UP_AUTO_SEND_HELP') }}
              </p>
              <p
                v-if="isLoadingMessagingWindow"
                class="mb-0 text-xs text-n-slate-10"
              >
                {{ t('CRM_KANBAN.DRAWER.FOLLOW_UP_WINDOW_LOADING') }}
              </p>
              <p
                v-else-if="requiresTemplateNow"
                class="mb-0 text-xs text-n-ruby-11"
              >
                {{ t('CRM_KANBAN.DRAWER.FOLLOW_UP_WINDOW_TEMPLATE_REQUIRED') }}
              </p>
              <p v-else class="mb-0 text-xs text-n-teal-11">
                {{ t('CRM_KANBAN.DRAWER.FOLLOW_UP_WINDOW_SESSION_OK') }}
              </p>

              <Input
                v-model="followUpForm.messageBody"
                :label="t('CRM_KANBAN.DRAWER.FOLLOW_UP_MESSAGE_BODY')"
                :placeholder="
                  t('CRM_KANBAN.DRAWER.FOLLOW_UP_MESSAGE_BODY_PLACEHOLDER')
                "
              />

              <label
                v-if="isWhatsappApiInbox && requiresTemplateNow"
                class="grid gap-1"
              >
                <span class="text-heading-3 text-n-slate-12">
                  {{ t('CRM_KANBAN.DRAWER.FOLLOW_UP_API_TEMPLATE') }}
                </span>
                <select
                  v-model="followUpForm.whatsappApiTemplateId"
                  class="reset-base !mb-0 h-10 w-full rounded-lg border-0 bg-n-surface-2 px-3 text-sm text-n-slate-12 outline outline-1 outline-n-weak focus:outline-n-brand"
                >
                  <option value="">
                    {{ t('CRM_KANBAN.DRAWER.FOLLOW_UP_TEMPLATE_PLACEHOLDER') }}
                  </option>
                  <option
                    v-for="option in whatsappApiTemplateOptions"
                    :key="option.value"
                    :value="option.value"
                  >
                    {{ option.label }}
                  </option>
                </select>
                <span
                  v-if="isLoadingWhatsappTemplates"
                  class="text-xs text-n-slate-10"
                >
                  {{ t('CRM_KANBAN.DRAWER.FOLLOW_UP_TEMPLATES_LOADING') }}
                </span>
              </label>

              <label
                v-else-if="isWhatsappNativeInbox && requiresTemplateNow"
                class="grid gap-1"
              >
                <span class="text-heading-3 text-n-slate-12">
                  {{ t('CRM_KANBAN.DRAWER.FOLLOW_UP_API_TEMPLATE') }}
                </span>
                <select
                  v-model="followUpForm.nativeTemplateKey"
                  class="reset-base !mb-0 h-10 w-full rounded-lg border-0 bg-n-surface-2 px-3 text-sm text-n-slate-12 outline outline-1 outline-n-weak focus:outline-n-brand"
                  @change="onNativeTemplateSelected"
                >
                  <option value="">
                    {{ t('CRM_KANBAN.DRAWER.FOLLOW_UP_TEMPLATE_PLACEHOLDER') }}
                  </option>
                  <option
                    v-for="option in nativeWhatsappTemplateOptions"
                    :key="option.value"
                    :value="option.value"
                  >
                    {{ option.label }}
                  </option>
                </select>
                <span
                  v-if="!nativeWhatsappTemplateOptions.length"
                  class="text-xs text-n-slate-10"
                >
                  {{ t('CRM_KANBAN.DRAWER.FOLLOW_UP_NATIVE_TEMPLATE_EMPTY') }}
                </span>
              </label>

              <template v-else-if="requiresTemplateNow">
                <Input
                  v-model="followUpForm.templateName"
                  :label="t('CRM_KANBAN.DRAWER.FOLLOW_UP_TEMPLATE_NAME')"
                  :placeholder="
                    t('CRM_KANBAN.DRAWER.FOLLOW_UP_TEMPLATE_NAME_PLACEHOLDER')
                  "
                />
                <Input
                  v-model="followUpForm.templateLanguage"
                  :label="t('CRM_KANBAN.DRAWER.FOLLOW_UP_TEMPLATE_LANGUAGE')"
                  placeholder="pt_BR"
                />
              </template>
            </div>

            <label class="grid gap-1">
              <span class="text-heading-3 text-n-slate-12">
                {{ t('CRM_KANBAN.DRAWER.FOLLOW_UP_DESCRIPTION') }}
              </span>
              <textarea
                v-model="followUpForm.description"
                rows="3"
                class="reset-base !mb-0 w-full rounded-lg border-0 bg-n-alpha-black2 px-3 py-2.5 text-sm text-n-slate-12 outline outline-1 outline-n-weak transition-all placeholder:text-n-slate-10 focus:outline-n-brand"
                :placeholder="
                  t('CRM_KANBAN.DRAWER.FOLLOW_UP_DESCRIPTION_PLACEHOLDER')
                "
              />
            </label>

            <div class="flex justify-end">
              <Button
                :label="t('CRM_KANBAN.DRAWER.FOLLOW_UP_CREATE')"
                icon="i-lucide-clock-3"
                :is-loading="isSavingFollowUp"
                :disabled="
                  !followUpForm.title.trim() ||
                  !followUpForm.dueAt ||
                  isSavingFollowUp
                "
                @click="createFollowUp"
              />
            </div>
          </div>

          <!-- 3) Automatic follow-up -->
          <CrmCardAutoFollowupStatus
            :card="props.card"
            @reset="$emit('refreshCard')"
          />

          <!-- 4) Completed follow-ups (bottom) -->
          <p
            v-if="completedFollowUps.length"
            class="mb-0 mt-1 text-[11px] font-semibold uppercase tracking-wide text-n-slate-10"
          >
            {{ t('CRM_KANBAN.DRAWER.FOLLOW_UP_COMPLETED_SECTION') }}
          </p>
          <article
            v-for="followUp in completedFollowUps"
            :key="followUp.id"
            class="grid gap-3 rounded-lg border border-n-weak bg-n-alpha-black2 p-4"
          >
            <div class="flex items-start justify-between gap-3">
              <div class="min-w-0">
                <p class="mb-1 truncate text-sm font-medium text-n-slate-12">
                  {{ followUp.title }}
                </p>
                <p class="mb-0 flex flex-wrap gap-2 text-xs text-n-slate-11">
                  <span>{{ formatDate(followUp.due_at) }}</span>
                  <span>{{ followUpAutomationLabel(followUp) }}</span>
                </p>
              </div>
              <span
                class="shrink-0 rounded-md px-2 py-1 text-[11px] font-medium"
                :class="followUpStatusClass(followUp)"
              >
                {{ followUpStatusLabel(followUp) }}
              </span>
            </div>
            <p
              v-if="followUp.description"
              class="mb-0 text-xs leading-5 text-n-slate-11"
            >
              {{ followUp.description }}
            </p>
            <div
              v-if="activeFollowUps.some(item => item.id === followUp.id)"
              class="flex justify-end gap-2"
            >
              <Button
                :label="t('CRM_KANBAN.DRAWER.FOLLOW_UP_COMPLETE')"
                icon="i-lucide-check"
                slate
                faded
                sm
                :is-loading="isSavingFollowUp"
                @click="$emit('completeFollowUp', followUp)"
              />
              <Button
                :label="t('CRM_KANBAN.DRAWER.FOLLOW_UP_CANCEL')"
                icon="i-lucide-x"
                ruby
                ghost
                sm
                :is-loading="isSavingFollowUp"
                @click="$emit('cancelFollowUp', followUp)"
              />
            </div>
          </article>

          <div
            v-if="!isFetchingFollowUps && followUps.length === 0"
            class="rounded-lg border border-dashed border-n-weak px-4 py-8 text-center"
          >
            <p class="mb-1 text-sm font-medium text-n-slate-12">
              {{ t('CRM_KANBAN.DRAWER.NO_FOLLOW_UPS_TITLE') }}
            </p>
            <p class="mb-0 text-xs leading-5 text-n-slate-11">
              {{ t('CRM_KANBAN.DRAWER.NO_FOLLOW_UPS_HELP') }}
            </p>
          </div>
        </section>

        <section v-else class="grid gap-3">
          <article
            v-for="entry in timelineEntries"
            :key="entry.id"
            class="grid grid-cols-[auto_1fr] gap-3 rounded-lg border border-n-weak bg-n-alpha-black2 p-4"
          >
            <span
              class="mt-0.5 flex size-8 items-center justify-center rounded-full"
              :class="entry.toneClass"
            >
              <span class="size-4" :class="[entry.icon]" />
            </span>
            <div class="min-w-0">
              <div class="flex items-start justify-between gap-3">
                <p class="mb-1 text-sm font-medium text-n-slate-12">
                  {{ entry.title }}
                </p>
                <span class="shrink-0 text-xs text-n-slate-10">
                  {{ entry.relativeTime }}
                </span>
              </div>
              <p class="mb-0 text-xs text-n-slate-11">
                {{ entry.actor }}
              </p>
              <p
                v-if="entry.detail"
                class="mb-0 mt-1 text-xs leading-5 text-n-slate-12"
              >
                {{ entry.detail }}
              </p>
            </div>
          </article>

          <div
            v-if="activities.length === 0"
            class="rounded-lg border border-dashed border-n-weak px-4 py-8 text-center"
          >
            <p class="mb-1 text-sm font-medium text-n-slate-12">
              {{ t('CRM_KANBAN.DRAWER.NO_TIMELINE_TITLE') }}
            </p>
            <p class="mb-0 text-xs leading-5 text-n-slate-11">
              {{ t('CRM_KANBAN.DRAWER.NO_TIMELINE_HELP') }}
            </p>
          </div>
        </section>
      </div>

      <div
        class="flex items-center justify-between gap-3 border-t border-n-weak px-6 py-4"
      >
        <div v-if="isEditing" class="flex items-center gap-2">
          <Button
            :label="t('CRM_KANBAN.DRAWER.ARCHIVE')"
            icon="i-lucide-archive"
            ruby
            ghost
            :is-loading="isArchiving"
            @click="$emit('archive')"
          />
          <Button
            v-if="meetingsEnabled && card?.id"
            :label="t('CRM_KANBAN.DRAWER.SCHEDULE_MEETING')"
            icon="i-lucide-video"
            variant="outline"
            color="slate"
            @click="$emit('scheduleMeeting', { cardId: card.id })"
          />
        </div>
        <span v-else />
        <div class="flex items-center gap-2">
          <Button
            :label="t('CRM_KANBAN.DRAWER.CANCEL')"
            slate
            faded
            @click="$emit('close')"
          />
          <Button
            :label="
              isEditing
                ? t('CRM_KANBAN.DRAWER.SAVE')
                : t('CRM_KANBAN.DRAWER.CREATE')
            "
            icon="i-lucide-check"
            :is-loading="isSaving"
            :disabled="!form.title.trim() || (!isEditing && !form.stageId)"
            @click="onSubmit"
          />
        </div>
      </div>

      <!-- Win deal dialog: value pre-filled (auto-filled by AI), confirm to win -->
      <div
        v-if="showWinDialog"
        class="absolute inset-0 z-[60] flex items-center justify-center bg-n-alpha-black2 p-6"
        @click.self="showWinDialog = false"
      >
        <div class="w-full max-w-sm p-5 rounded-xl bg-n-solid-1 shadow-lg">
          <h3 class="mb-1 text-base font-medium text-n-slate-12">
            {{ t('CRM_KANBAN.DRAWER.WIN_DIALOG_TITLE') }}
          </h3>
          <p
            v-if="aiFilledValue"
            class="flex items-center gap-1 mb-3 text-xs text-n-slate-11"
          >
            <span class="i-lucide-sparkles" />
            {{ t('CRM_KANBAN.DRAWER.VALUE_AI_FILLED') }}
          </p>
          <div class="grid gap-3">
            <Input
              v-model="winAmount"
              type="number"
              :label="t('CRM_KANBAN.DRAWER.WIN_VALUE_LABEL')"
              placeholder="0,00"
            />
            <Input
              v-model="winCurrency"
              :label="t('CRM_KANBAN.DRAWER.WIN_CURRENCY_LABEL')"
              placeholder="BRL"
            />
          </div>
          <div class="flex items-center justify-end gap-2 mt-5">
            <Button
              :label="t('CRM_KANBAN.DRAWER.CANCEL')"
              slate
              faded
              sm
              @click="showWinDialog = false"
            />
            <Button
              :label="t('CRM_KANBAN.DRAWER.WIN_CONFIRM')"
              teal
              sm
              icon="i-lucide-trophy"
              @click="confirmWin"
            />
          </div>
        </div>
      </div>

      <!-- Lose deal dialog: optional reason -->
      <div
        v-if="showLoseDialog"
        class="absolute inset-0 z-[60] flex items-center justify-center bg-n-alpha-black2 p-6"
        @click.self="showLoseDialog = false"
      >
        <div class="w-full max-w-sm p-5 rounded-xl bg-n-solid-1 shadow-lg">
          <h3 class="mb-3 text-base font-medium text-n-slate-12">
            {{ t('CRM_KANBAN.DRAWER.LOSE_DIALOG_TITLE') }}
          </h3>
          <Input
            v-model="loseReason"
            :label="t('CRM_KANBAN.DRAWER.LOSE_REASON_LABEL')"
            :placeholder="t('CRM_KANBAN.DRAWER.LOSE_REASON_PLACEHOLDER')"
          />
          <div class="flex items-center justify-end gap-2 mt-5">
            <Button
              :label="t('CRM_KANBAN.DRAWER.CANCEL')"
              slate
              faded
              sm
              @click="showLoseDialog = false"
            />
            <Button
              :label="t('CRM_KANBAN.DRAWER.LOSE_CONFIRM')"
              ruby
              sm
              icon="i-lucide-circle-x"
              @click="confirmLose"
            />
          </div>
        </div>
      </div>
    </div>
  </transition>
</template>
