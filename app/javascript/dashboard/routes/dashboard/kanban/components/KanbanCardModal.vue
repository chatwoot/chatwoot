<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useRouter, useRoute } from 'vue-router';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';
import ResolutionModal from 'dashboard/components-next/ConversationWorkflow/ResolutionModal.vue';

const props = defineProps({
  card: { type: Object, required: true },
});

const emit = defineEmits(['close']);

const { t } = useI18n();
const store = useStore();
const router = useRouter();
const route = useRoute();

function closeModal() {
  emit('close');
}

const activeTab = ref('details');
const tabs = ['details', 'conversations', 'history', 'schedules'];

const potentialValue = ref(props.card.potential_value ?? '');
const notes = ref(props.card.notes ?? '');
const selectedColumnId = ref(props.card.kanban_column_id);
const isSaving = ref(false);

const conversations = ref([]);
const isLoadingConversations = ref(false);

const schedules = ref([...(props.card.schedules || [])]);
const isCreatingSchedule = ref(false);
const newScheduleTitle = ref('');
const newScheduleDescription = ref('');
const newScheduleAt = ref('');
const scheduleError = ref('');

const resolutionModalRef = ref(null);
const pendingColumnMove = ref(null);

const contact = computed(() => props.card.contact);
const columns = computed(() => store.getters['kanban/getColumns']);

const openConversation = computed(() =>
  conversations.value.find(c => c.status === 'open')
);

const expiresAt = computed(() => {
  if (!openConversation.value) return null;
  const created = new Date(openConversation.value.created_at * 1000);
  return new Date(created.getTime() + 24 * 60 * 60 * 1000);
});

const formattedExpiry = computed(() => {
  if (!expiresAt.value) return null;
  return new Intl.DateTimeFormat('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(expiresAt.value);
});

const expiryStatus = computed(() => {
  if (!expiresAt.value) return null;
  const now = new Date();
  const diff = expiresAt.value - now;
  if (diff < 0) return 'expired';
  if (diff < 2 * 60 * 60 * 1000) return 'critical';
  if (diff < 6 * 60 * 60 * 1000) return 'warning';
  return 'ok';
});

const formattedValue = computed(() => {
  if (!potentialValue.value) return null;
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL',
  }).format(potentialValue.value);
});

const PRIORITY_OPTIONS = [
  {
    value: null,
    label: t('KANBAN.CARD.PRIORITY.NONE'),
    color: 'text-slate-400',
  },
  {
    value: 'low',
    label: t('KANBAN.CARD.PRIORITY.LOW'),
    color: 'text-blue-500',
  },
  {
    value: 'medium',
    label: t('KANBAN.CARD.PRIORITY.MEDIUM'),
    color: 'text-yellow-500',
  },
  {
    value: 'high',
    label: t('KANBAN.CARD.PRIORITY.HIGH'),
    color: 'text-orange-500',
  },
  {
    value: 'urgent',
    label: t('KANBAN.CARD.PRIORITY.URGENT'),
    color: 'text-red-500',
  },
];

const conversationPriority = ref(null);
const initialPriority = ref(null);

function activityLabel(a) {
  const systemActor = t('KANBAN.CARD.TIMELINE.SYSTEM');
  const macroName = a.metadata?.macro_name;
  const classification = a.metadata?.classification_name;
  const reason = a.metadata?.reason;

  if (a.event_type === 'stage_changed') {
    if (a.source === 'macro' && macroName) {
      return t('KANBAN.CARD.TIMELINE.STAGE_CHANGED_BY_MACRO', {
        macro: macroName,
        to: a.to_column_name || '—',
      });
    }
    if (a.source === 'system') {
      return t('KANBAN.CARD.TIMELINE.STAGE_CHANGED_BY_SYSTEM', {
        to: a.to_column_name || '—',
      });
    }
    return t('KANBAN.CARD.TIMELINE.MOVED', {
      from: a.from_column_name || '—',
      to: a.to_column_name || '—',
      user: a.user_name || systemActor,
    });
  }
  if (a.event_type === 'conversation_closed') {
    return classification
      ? t('KANBAN.CARD.TIMELINE.CONVERSATION_CLOSED', { classification })
      : t('KANBAN.CARD.TIMELINE.CONVERSATION_CLOSED_NO_CLASSIFICATION');
  }
  if (a.event_type === 'closure_cancelled') {
    return t('KANBAN.CARD.TIMELINE.CLOSURE_CANCELLED', {
      reason: reason || 'manual_reopen',
    });
  }
  if (a.event_type === 'macro_triggered' && macroName) {
    return t('KANBAN.CARD.TIMELINE.MACRO_TRIGGERED', { macro: macroName });
  }
  return t('KANBAN.CARD.TIMELINE.UNKNOWN_EVENT');
}

const activityLog = computed(() => {
  const events = [];
  events.push({
    id: `created-${props.card.id}`,
    type: 'created',
    label: t('KANBAN.CARD.TIMELINE.CREATED'),
    timestamp: props.card.created_at,
  });
  (props.card.activities || [])
    .slice()
    .reverse()
    .forEach(a => {
      events.push({
        id: a.id,
        type: a.event_type || 'moved',
        label: activityLabel(a),
        timestamp: a.created_at,
      });
    });
  return events;
});

function formatDate(ts) {
  if (!ts) return '';
  return new Intl.DateTimeFormat('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(ts));
}

function formatConvStatus(status) {
  const map = {
    open: t('KANBAN.CARD.CONV_STATUS.OPEN'),
    resolved: t('KANBAN.CARD.CONV_STATUS.RESOLVED'),
    pending: t('KANBAN.CARD.CONV_STATUS.PENDING'),
  };
  return map[status] || status;
}

onMounted(async () => {
  if (!contact.value?.id) return;
  isLoadingConversations.value = true;
  try {
    await Promise.all([
      store.dispatch('contactConversations/get', contact.value.id),
      store.dispatch('contacts/fetchContactableInbox', contact.value.id),
    ]);
    conversations.value =
      store.getters['contactConversations/getContactConversation'](
        contact.value.id
      ) || [];
    if (openConversation.value) {
      conversationPriority.value = openConversation.value.priority || null;
      initialPriority.value = conversationPriority.value;
    }
  } catch {
    // silent — conversations are optional
  } finally {
    isLoadingConversations.value = false;
  }
});

async function save() {
  isSaving.value = true;
  try {
    await store.dispatch('kanban/updateCard', {
      id: props.card.id,
      potential_value: potentialValue.value || null,
      notes: notes.value || null,
    });

    if (
      openConversation.value &&
      conversationPriority.value !== initialPriority.value
    ) {
      await store.dispatch('assignPriority', {
        conversationId: openConversation.value.id,
        priority: conversationPriority.value,
      });
      initialPriority.value = conversationPriority.value;
    }

    const isColumnChanging =
      String(selectedColumnId.value) !== String(props.card.kanban_column_id);

    if (isColumnChanging) {
      const targetColumn = columns.value.find(
        c => String(c.id) === String(selectedColumnId.value)
      );
      const needsResolution =
        targetColumn?.column_type === 'won' ||
        targetColumn?.column_type === 'lost';

      if (needsResolution && openConversation.value) {
        pendingColumnMove.value = { targetColumnId: selectedColumnId.value };
        resolutionModalRef.value?.open({
          conversationId: openConversation.value.id,
          lockedClassificationName:
            targetColumn.column_type === 'won'
              ? t('KANBAN.COLUMN.WON_CLASSIFICATION')
              : null,
          excludeClassificationNames:
            targetColumn.column_type === 'lost'
              ? [t('KANBAN.COLUMN.WON_CLASSIFICATION')]
              : [],
        });
        return;
      }

      await store.dispatch('kanban/moveCard', {
        card: props.card,
        targetColumnId: selectedColumnId.value,
        beforePosition: null,
        afterPosition: null,
      });
    }
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[KanbanCardModal] save error:', err);
  } finally {
    isSaving.value = false;
    if (!pendingColumnMove.value) closeModal();
  }
}

async function handleResolutionSubmit({
  context,
  classificationId,
  closingNote,
}) {
  pendingColumnMove.value = null;
  await store.dispatch('kanban/moveCard', {
    card: props.card,
    targetColumnId: selectedColumnId.value,
    beforePosition: null,
    afterPosition: null,
  });
  await store.dispatch('toggleStatus', {
    conversationId: context.conversationId,
    status: 'resolved',
    classificationId,
    closingNote,
  });
  closeModal();
}

function handleResolutionCancel() {
  pendingColumnMove.value = null;
  selectedColumnId.value = props.card.kanban_column_id;
}

function setPriority(priority) {
  if (!openConversation.value) return;
  conversationPriority.value = priority;
}

function openContact() {
  closeModal();
  router.push({
    name: 'contacts_edit',
    params: { accountId: route.params.accountId, contactId: contact.value.id },
  });
}

function goToConversation(conv) {
  closeModal();
  router.push({
    name: 'inbox_conversation',
    params: { accountId: route.params.accountId, conversation_id: conv.id },
  });
}

async function createSchedule() {
  if (!newScheduleTitle.value.trim() || !newScheduleAt.value) return;
  scheduleError.value = '';
  isCreatingSchedule.value = true;
  try {
    const data = await store.dispatch('kanban/createSchedule', {
      cardId: props.card.id,
      params: {
        title: newScheduleTitle.value.trim(),
        description: newScheduleDescription.value.trim() || null,
        scheduled_at: newScheduleAt.value,
      },
    });
    schedules.value.push(data);
    newScheduleTitle.value = '';
    newScheduleDescription.value = '';
    newScheduleAt.value = '';
  } catch (err) {
    scheduleError.value =
      err?.response?.data?.error || t('KANBAN.CARD.SCHEDULE.ERROR_GENERIC');
  } finally {
    isCreatingSchedule.value = false;
  }
}

async function cancelSchedule(schedule) {
  try {
    await store.dispatch('kanban/deleteSchedule', {
      cardId: props.card.id,
      scheduleId: schedule.id,
    });
    schedules.value = schedules.value.filter(s => s.id !== schedule.id);
  } catch {
    // silent
  }
}
</script>

<template>
  <Teleport to="body">
    <!-- Backdrop + container centralizador (uma coisa só) -->
    <!-- @click.self: só dispara se o clique foi DIRETAMENTE no backdrop, não em descendentes -->
    <div
      class="fixed inset-0 z-[9989] bg-black/50 flex items-center justify-center"
      @click.self="closeModal"
    >
      <!-- Painel central -->
      <div
        class="bg-white dark:bg-slate-800 rounded-xl shadow-xl w-full max-w-2xl mx-4 flex flex-col max-h-[90vh]"
      >
        <!-- Header -->
        <div
          class="flex items-center justify-between px-5 py-4 border-b border-slate-200 dark:border-slate-700 flex-shrink-0"
        >
          <div class="flex items-center gap-3 min-w-0">
            <div
              class="w-10 h-10 rounded-full bg-woot-500 text-white flex items-center justify-center font-semibold text-sm flex-shrink-0"
            >
              {{ contact?.name?.[0]?.toUpperCase() }}
            </div>
            <div class="min-w-0">
              <p
                class="font-semibold text-slate-800 dark:text-slate-100 truncate"
              >
                {{ contact?.name }}
              </p>
              <p class="text-xs text-slate-500 truncate">
                {{ contact?.phone_number }}
              </p>
            </div>
          </div>
          <button
            class="text-slate-400 hover:text-slate-600 flex-shrink-0 ml-2 p-1"
            @click="closeModal"
          >
            <fluent-icon icon="dismiss" size="16" />
          </button>
        </div>

        <!-- Quick actions -->
        <div class="flex gap-2 px-5 pt-3 pb-2 flex-shrink-0">
          <button
            class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-slate-200 dark:border-slate-700 text-xs text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700"
            @click="openContact"
          >
            <fluent-icon icon="person" size="12" />
            {{ $t('KANBAN.CARD.OPEN_CONTACT') }}
          </button>
          <button
            v-if="conversations.length > 0 || isLoadingConversations"
            class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-woot-400 text-xs text-woot-600 dark:text-woot-400 hover:bg-woot-50 dark:hover:bg-woot-900/20"
            @click="goToConversation(conversations[0])"
          >
            <fluent-icon icon="chat" size="12" />
            <span v-if="isLoadingConversations">...</span>
            <span v-else>{{ $t('KANBAN.CARD.OPEN_CONVERSATION') }}</span>
          </button>
          <ComposeConversation
            v-else
            :contact-id="contact?.id ? String(contact.id) : null"
            is-modal
            @close="() => {}"
          >
            <template #trigger="{ toggle }">
              <button
                class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-woot-400 text-xs text-woot-600 dark:text-woot-400 hover:bg-woot-50 dark:hover:bg-woot-900/20"
                @click="toggle"
              >
                <fluent-icon icon="chat" size="12" />
                {{ $t('KANBAN.CARD.NEW_CONVERSATION') }}
              </button>
            </template>
          </ComposeConversation>
        </div>

        <!-- Tabs -->
        <div
          class="flex border-b border-slate-200 dark:border-slate-700 px-5 flex-shrink-0"
        >
          <button
            v-for="tab in tabs"
            :key="tab"
            class="px-3 py-2 text-xs font-medium border-b-2 -mb-px transition-colors"
            :class="
              activeTab === tab
                ? 'border-woot-500 text-woot-600 dark:text-woot-400'
                : 'border-transparent text-slate-500 hover:text-slate-700 dark:hover:text-slate-300'
            "
            @click="activeTab = tab"
          >
            {{ $t(`KANBAN.CARD.TAB.${tab.toUpperCase()}`) }}
          </button>
        </div>

        <!-- Tab content -->
        <div class="flex-1 overflow-y-auto">
          <!-- ── Tab: Detalhes ── -->
          <div v-if="activeTab === 'details'" class="p-5 space-y-4">
            <!-- Urgência -->
            <div>
              <label
                class="block text-xs font-medium text-slate-600 dark:text-slate-300 mb-1.5"
              >
                {{ $t('KANBAN.CARD.PRIORITY.LABEL') }}
              </label>
              <div class="flex gap-1.5 flex-wrap">
                <button
                  v-for="opt in PRIORITY_OPTIONS"
                  :key="String(opt.value)"
                  class="px-2.5 py-1 rounded-full text-xs font-medium border transition-colors"
                  :class="
                    conversationPriority === opt.value
                      ? 'bg-woot-500 text-white border-woot-500'
                      : 'border-slate-300 dark:border-slate-600 text-slate-600 dark:text-slate-300 hover:border-woot-400'
                  "
                  :disabled="!openConversation"
                  @click="setPriority(opt.value)"
                >
                  {{ opt.label }}
                </button>
              </div>
              <p
                v-if="!openConversation && !isLoadingConversations"
                class="text-xs text-slate-400 mt-1"
              >
                {{ $t('KANBAN.CARD.PRIORITY.NO_CONVERSATION') }}
              </p>
            </div>

            <!-- Vencimento -->
            <div v-if="formattedExpiry">
              <label
                class="block text-xs font-medium text-slate-600 dark:text-slate-300 mb-1"
              >
                {{ $t('KANBAN.CARD.EXPIRY.LABEL') }}
              </label>
              <div
                class="flex items-center gap-2 px-3 py-1.5 rounded-lg text-xs font-medium"
                :class="{
                  'bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400':
                    expiryStatus === 'expired',
                  'bg-orange-50 dark:bg-orange-900/20 text-orange-600 dark:text-orange-400':
                    expiryStatus === 'critical',
                  'bg-yellow-50 dark:bg-yellow-900/20 text-yellow-600 dark:text-yellow-400':
                    expiryStatus === 'warning',
                  'bg-green-50 dark:bg-green-900/20 text-green-600 dark:text-green-400':
                    expiryStatus === 'ok',
                }"
              >
                <svg
                  width="12"
                  height="12"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  class="flex-shrink-0"
                >
                  <circle cx="12" cy="12" r="10" />
                  <polyline points="12 6 12 12 16 14" />
                </svg>
                {{
                  expiryStatus === 'expired'
                    ? $t('KANBAN.CARD.EXPIRY.EXPIRED')
                    : formattedExpiry
                }}
              </div>
            </div>

            <!-- Valor potencial -->
            <div>
              <label
                class="block text-xs font-medium text-slate-600 dark:text-slate-300 mb-1"
              >
                {{ $t('KANBAN.ADD_CARD.POTENTIAL_VALUE') }}
              </label>
              <input
                v-model="potentialValue"
                type="number"
                min="0"
                step="0.01"
                class="w-full text-sm rounded border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 px-3 py-1.5 focus:outline-none focus:ring-1 focus:ring-woot-500"
              />
              <p v-if="formattedValue" class="text-xs text-green-600 mt-0.5">
                {{ formattedValue }}
              </p>
            </div>

            <!-- Notas -->
            <div>
              <label
                class="block text-xs font-medium text-slate-600 dark:text-slate-300 mb-1"
              >
                {{ $t('KANBAN.ADD_CARD.NOTES') }}
              </label>
              <textarea
                v-model="notes"
                rows="3"
                class="w-full text-sm rounded border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 px-3 py-1.5 focus:outline-none focus:ring-1 focus:ring-woot-500 resize-none"
              />
            </div>

            <!-- Mover para coluna -->
            <div>
              <label
                class="block text-xs font-medium text-slate-600 dark:text-slate-300 mb-1"
              >
                {{ $t('KANBAN.CARD.MOVE_TO_COLUMN') }}
              </label>
              <select
                v-model="selectedColumnId"
                class="w-full text-sm rounded border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 px-3 py-1.5 focus:outline-none focus:ring-1 focus:ring-woot-500"
              >
                <option v-for="col in columns" :key="col.id" :value="col.id">
                  {{ col.name }}
                </option>
              </select>
            </div>
          </div>

          <!-- ── Tab: Conversas ── -->
          <div v-else-if="activeTab === 'conversations'" class="p-5">
            <div
              v-if="isLoadingConversations"
              class="text-center py-8 text-slate-400 text-sm"
            >
              {{ $t('KANBAN.CARD.LOADING') }}
            </div>
            <div
              v-else-if="!conversations.length"
              class="text-center py-8 text-slate-400 text-sm"
            >
              {{ $t('KANBAN.CARD.NO_CONVERSATIONS') }}
            </div>
            <ul v-else class="space-y-2">
              <li
                v-for="conv in conversations"
                :key="conv.id"
                class="flex items-center justify-between p-3 rounded-lg border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-700 cursor-pointer"
                @click="goToConversation(conv)"
              >
                <div class="min-w-0">
                  <div class="flex items-center gap-2">
                    <span
                      class="text-xs px-1.5 py-0.5 rounded font-medium"
                      :class="{
                        'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400':
                          conv.status === 'open',
                        'bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-300':
                          conv.status === 'resolved',
                        'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400':
                          conv.status === 'pending',
                      }"
                    >
                      {{ formatConvStatus(conv.status) }}
                    </span>
                    <span class="text-xs text-slate-500"
                      >#{{ conv.display_id }}</span
                    >
                  </div>
                  <p
                    class="text-sm text-slate-700 dark:text-slate-200 mt-0.5 truncate"
                  >
                    {{ conv.meta?.channel || conv.inbox_id }}
                  </p>
                </div>
                <div class="text-right flex-shrink-0 ml-2">
                  <p class="text-xs text-slate-400">
                    {{ formatDate(conv.created_at * 1000) }}
                  </p>
                  <fluent-icon
                    icon="arrow-right"
                    size="12"
                    class="text-slate-400 mt-1"
                  />
                </div>
              </li>
            </ul>
          </div>

          <!-- ── Tab: Histórico ── -->
          <div v-else-if="activeTab === 'history'" class="p-5">
            <ul
              v-if="activityLog.length"
              class="relative border-l border-slate-200 dark:border-slate-700 ml-2 space-y-4"
            >
              <li
                v-for="event in activityLog"
                :key="event.id"
                class="pl-5 relative"
              >
                <span
                  class="absolute -left-1.5 top-1 w-3 h-3 rounded-full border-2 border-white dark:border-slate-800"
                  :class="
                    event.type === 'created' ? 'bg-woot-500' : 'bg-slate-400'
                  "
                />
                <p class="text-sm text-slate-700 dark:text-slate-200">
                  {{ event.label }}
                </p>
                <p class="text-xs text-slate-400 mt-0.5">
                  {{ formatDate(event.timestamp) }}
                </p>
              </li>
            </ul>
            <p v-else class="text-center py-8 text-slate-400 text-sm">
              {{ $t('KANBAN.CARD.NO_HISTORY') }}
            </p>
          </div>

          <!-- ── Tab: Agendamentos ── -->
          <div v-else-if="activeTab === 'schedules'" class="p-5 space-y-4">
            <div v-if="schedules.length" class="space-y-2">
              <div
                v-for="s in schedules"
                :key="s.id"
                class="flex items-start justify-between p-3 rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900"
              >
                <div class="min-w-0">
                  <p
                    class="text-sm font-medium text-slate-800 dark:text-slate-100"
                  >
                    {{ s.title }}
                  </p>
                  <p v-if="s.description" class="text-xs text-slate-500 mt-0.5">
                    {{ s.description }}
                  </p>
                  <p class="text-xs text-woot-500 mt-1">
                    <svg
                      width="11"
                      height="11"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      class="inline -mt-0.5"
                    >
                      <circle cx="12" cy="12" r="10" />
                      <polyline points="12 6 12 12 16 14" />
                    </svg>
                    {{ formatDate(s.scheduled_at) }}
                  </p>
                </div>
                <button
                  class="ml-3 flex-shrink-0 text-slate-400 hover:text-red-500"
                  :title="$t('KANBAN.CARD.SCHEDULE.CANCEL')"
                  @click="cancelSchedule(s)"
                >
                  <fluent-icon icon="dismiss-circle" size="16" />
                </button>
              </div>
            </div>
            <p v-else class="text-xs text-slate-400 text-center py-2">
              {{ $t('KANBAN.CARD.SCHEDULE.NONE') }}
            </p>

            <div
              class="border border-slate-200 dark:border-slate-700 rounded-lg p-3 space-y-3"
            >
              <p
                class="text-xs font-semibold text-slate-700 dark:text-slate-200"
              >
                {{ $t('KANBAN.CARD.SCHEDULE.NEW') }}
              </p>
              <input
                v-model="newScheduleTitle"
                class="w-full text-sm rounded border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 px-3 py-1.5 focus:outline-none focus:ring-1 focus:ring-woot-500"
                :placeholder="$t('KANBAN.CARD.SCHEDULE.TITLE_PLACEHOLDER')"
              />
              <textarea
                v-model="newScheduleDescription"
                rows="2"
                class="w-full text-sm rounded border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 px-3 py-1.5 focus:outline-none focus:ring-1 focus:ring-woot-500 resize-none"
                :placeholder="$t('KANBAN.CARD.SCHEDULE.DESC_PLACEHOLDER')"
              />
              <input
                v-model="newScheduleAt"
                type="datetime-local"
                class="w-full text-sm rounded border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 px-3 py-1.5 focus:outline-none focus:ring-1 focus:ring-woot-500"
              />
              <p v-if="scheduleError" class="text-xs text-red-500">
                {{ scheduleError }}
              </p>
              <button
                class="w-full py-1.5 text-xs bg-woot-500 text-white rounded hover:bg-woot-600 disabled:opacity-50"
                :disabled="
                  isCreatingSchedule ||
                  !newScheduleTitle.trim() ||
                  !newScheduleAt
                "
                @click="createSchedule"
              >
                {{ $t('KANBAN.CARD.SCHEDULE.SUBMIT') }}
              </button>
            </div>
          </div>
        </div>

        <!-- Footer (only for details tab) -->
        <div
          v-if="activeTab === 'details'"
          class="flex justify-end gap-2 px-5 py-3 border-t border-slate-200 dark:border-slate-700 flex-shrink-0"
        >
          <button
            class="px-4 py-2 text-sm rounded border border-slate-300 dark:border-slate-600 text-slate-600 dark:text-slate-300 hover:bg-slate-50"
            @click="closeModal"
          >
            {{ $t('KANBAN.CARD.CANCEL') }}
          </button>
          <button
            class="px-4 py-2 text-sm rounded bg-woot-500 text-white hover:bg-woot-600 disabled:opacity-50"
            :disabled="isSaving"
            @click="save"
          >
            {{ $t('KANBAN.CARD.SAVE') }}
          </button>
        </div>
      </div>
    </div>
  </Teleport>
  <ResolutionModal
    ref="resolutionModalRef"
    @submit="handleResolutionSubmit"
    @cancel="handleResolutionCancel"
  />
</template>
