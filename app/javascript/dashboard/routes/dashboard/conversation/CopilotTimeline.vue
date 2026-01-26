<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import conversationsAPI from 'dashboard/api/conversations';

const { t } = useI18n();

const route = useRoute();
const events = ref([]);
const loading = ref(false);
const error = ref(null);

const conversationId = computed(() => route.params.conversation_id);

const fetchCopilotEvents = async () => {
  if (!conversationId.value) return;

  loading.value = true;
  error.value = null;

  try {
    const response = await conversationsAPI.getCopilotEvents(
      conversationId.value
    );
    events.value = response.data.events || [];
  } catch (err) {
    console.error('Error fetching copilot events:', err);
    error.value = 'Error al cargar eventos de copilots';
    events.value = [];
  } finally {
    loading.value = false;
  }
};

const getEventIcon = eventType => {
  const icons = {
    enrolled: 'i-lucide-user-plus',
    step_executed: 'i-lucide-check-circle',
    step_failed: 'i-lucide-x-circle',
    message_sent: 'i-lucide-message-square',
    template_sent: 'i-lucide-file-text',
    sms_sent: 'i-lucide-mail',
    ai_response_received: 'i-lucide-sparkles',
    label_added: 'i-lucide-tag',
    label_removed: 'i-lucide-tag',
    agent_assigned: 'i-lucide-user-check',
    team_assigned: 'i-lucide-users',
    pipeline_status_updated: 'i-lucide-workflow',
    webhook_called: 'i-lucide-webhook',
    completed: 'i-lucide-check-check',
    cancelled: 'i-lucide-x',
    failed: 'i-lucide-alert-triangle',
    paused: 'i-lucide-pause-circle',
    resumed: 'i-lucide-play-circle',
  };
  return icons[eventType] || 'i-lucide-circle';
};

const getEventColor = eventType => {
  const colors = {
    enrolled: 'text-n-teal-11',
    step_executed: 'text-n-green-11',
    step_failed: 'text-n-ruby-11',
    message_sent: 'text-n-blue-11',
    template_sent: 'text-n-blue-11',
    sms_sent: 'text-n-blue-11',
    ai_response_received: 'text-n-purple-11',
    label_added: 'text-n-amber-11',
    label_removed: 'text-n-amber-11',
    agent_assigned: 'text-n-indigo-11',
    team_assigned: 'text-n-indigo-11',
    pipeline_status_updated: 'text-n-violet-11',
    webhook_called: 'text-n-cyan-11',
    completed: 'text-n-teal-11',
    cancelled: 'text-n-slate-11',
    failed: 'text-n-ruby-11',
    paused: 'text-n-amber-11',
    resumed: 'text-n-green-11',
  };
  return colors[eventType] || 'text-n-slate-11';
};

const getEventDescription = event => {
  const { event_type: type, metadata } = event;
  const i18nKey = `LEAD_RETARGETING.EVENTS.${type}`;

  switch (type) {
    case 'enrolled':
      return t(i18nKey, { name: event.copilot_name || '' });
    case 'step_executed':
      return t(i18nKey, { name: metadata.step_name || event.step_id });
    case 'step_failed':
      return t(i18nKey, { error: metadata.error_message });
    case 'message_sent':
      return t(i18nKey, { channel: metadata.channel || 'WhatsApp' });
    case 'template_sent':
      return t(i18nKey, { name: metadata.template_name });
    case 'label_added':
    case 'label_removed':
      return t(i18nKey, { labels: (metadata.labels || []).join(', ') });
    case 'agent_assigned':
      return t(i18nKey, { name: metadata.agent_name });
    case 'team_assigned':
      return t(i18nKey, { name: metadata.team_name });
    case 'pipeline_status_updated':
      return t(i18nKey, { name: metadata.status_name });
    case 'webhook_called':
      return t(i18nKey, { url: metadata.url });
    case 'completed':
      return t(i18nKey, { reason: metadata.completion_reason || '' });
    case 'cancelled':
      return t(i18nKey, { reason: metadata.cancellation_reason || '' });
    case 'failed':
      return t(i18nKey, { error: metadata.error_message });
    default:
      return t(i18nKey);
  }
};

const formatDate = dateString => {
  if (!dateString) return '-';
  const date = new Date(dateString);
  const now = new Date();
  const diffMs = now - date;
  const diffMins = Math.floor(diffMs / 60000);

  if (diffMins < 1) return t('LEAD_RETARGETING.TIMELINE.JUST_NOW') || 'Hace un momento';
  if (diffMins < 60) return `${t('LEAD_RETARGETING.TIMELINE.AGO')} ${diffMins}min`;

  const diffHours = Math.floor(diffMins / 60);
  if (diffHours < 24) return `${t('LEAD_RETARGETING.TIMELINE.AGO')} ${diffHours}h`;

  const diffDays = Math.floor(diffHours / 24);
  if (diffDays < 7) return `${t('LEAD_RETARGETING.TIMELINE.AGO')} ${diffDays}d`;

  return date.toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
};

const hasEvents = computed(() => events.value.length > 0);

onMounted(() => {
  fetchCopilotEvents();
});
</script>

<template>
  <div class="copilot-timeline">
    <!-- Loading State -->
    <div v-if="loading" class="p-4 text-center">
      <div
        class="inline-block animate-spin i-lucide-loader-2 text-n-slate-11"
      />
      <p class="mt-2 text-xs text-n-slate-11">
        {{ t('LEAD_RETARGETING.TIMELINE.LOADING') }}
      </p>
    </div>

    <!-- Error State -->
    <div v-else-if="error" class="p-4 text-center">
      <i class="i-lucide-alert-circle text-n-ruby-11 text-xl" />
      <p class="mt-2 text-xs text-n-ruby-11">
        {{ error }}
      </p>
    </div>

    <!-- Empty State -->
    <div v-else-if="!hasEvents" class="p-4 text-center">
      <i class="i-lucide-info text-n-slate-11 text-xl" />
      <p class="mt-2 text-xs text-n-slate-11">
        {{ t('LEAD_RETARGETING.TIMELINE.EMPTY_STATE') }}
      </p>
    </div>

    <!-- Events List -->
    <div v-else class="flex flex-col">
      <div
        v-for="event in events"
        :key="event.id"
        class="group relative flex gap-3 p-3 hover:bg-n-weak/50 transition-colors border-b border-n-weak last:border-0"
      >
        <!-- Timeline Line -->
        <div
          class="absolute left-[22px] top-10 bottom-0 w-px bg-n-weak group-last:hidden"
        />

        <!-- Event Icon -->
        <div class="flex-shrink-0 relative z-10">
          <div
            class="flex items-center justify-center w-6 h-6 rounded-full bg-n-background border border-n-weak"
          >
            <i
              class="text-sm"
              :class="[
                getEventIcon(event.event_type),
                getEventColor(event.event_type),
              ]"
            />
          </div>
        </div>

        <!-- Event Content -->
        <div class="flex-1 min-w-0">
          <!-- Copilot Name (Textual & Clear) -->
          <div v-if="event.copilot_name" class="flex items-center gap-1 mb-1">
            <span
              class="text-[10px] uppercase tracking-wider font-bold text-n-slate-11 bg-n-weak/30 px-1.5 py-0.5 rounded border border-n-weak/50"
            >
              {{ event.copilot_name }}
            </span>
          </div>

          <!-- Event Description -->
          <p class="text-sm text-n-slate-12 font-medium">
            {{ getEventDescription(event) }}
          </p>

          <!-- Status / Reason (if any terminal event) -->
          <div
            v-if="
              event.metadata &&
              (event.metadata.completion_reason ||
                event.metadata.cancellation_reason ||
                event.metadata.error_message)
            "
            class="mt-1"
          >
            <p
              class="text-xs"
              :class="
                event.metadata.error_message
                  ? 'text-n-ruby-11'
                  : 'text-n-slate-11'
              "
            >
              {{
                event.metadata.error_message ||
                event.metadata.completion_reason ||
                event.metadata.cancellation_reason
              }}
            </p>
          </div>

          <!-- Timestamp -->
          <div class="mt-1">
            <span class="text-xs text-n-slate-11">
              {{ formatDate(event.occurred_at) }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.copilot-timeline {
  max-height: 600px;
  overflow-y: auto;
}
</style>
