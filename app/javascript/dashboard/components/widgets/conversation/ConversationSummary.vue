<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import TasksAPI from 'dashboard/api/captain/tasks';
import Button from 'dashboard/components-next/button/Button.vue';
import { useTrack } from 'dashboard/composables';
import { CAPTAIN_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

const props = defineProps({
  chat: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();
const { isCloudFeatureEnabled } = useAccount();
const { formatMessage } = useMessageFormatter();

const isExpanded = ref(false);
const isLoading = ref(false);
const error = ref('');

const captainTasksEnabled = computed(() => {
  return isCloudFeatureEnabled(FEATURE_FLAGS.CAPTAIN_TASKS);
});

const cachedSummary = computed(() => props.chat?.cached_summary || '');
const cachedSummaryAt = computed(() => props.chat?.cached_summary_at || 0);
const lastActivityAt = computed(() => props.chat?.last_activity_at || 0);

const isStale = computed(() => {
  if (!cachedSummaryAt.value) return true;
  return lastActivityAt.value > cachedSummaryAt.value;
});

const formattedSummary = computed(() => {
  return cachedSummary.value ? formatMessage(cachedSummary.value) : '';
});

const fetchSummary = async () => {
  isLoading.value = true;
  error.value = '';
  try {
    const result = await TasksAPI.summarize(props.chat.id, {
      forceRegenerate: false,
    });
    const {
      data: { message: generatedSummary },
    } = result;

    if (generatedSummary) {
      store.dispatch('updateConversationCachedSummary', {
        conversationId: props.chat.id,
        cachedSummary: generatedSummary,
        cachedSummaryAt: Math.floor(Date.now() / 1000),
      });
    }
  } catch (e) {
    if (e.name !== 'AbortError' && e.name !== 'CanceledError') {
      error.value = e.response?.data?.error || t('CHAT_LIST.SUMMARY.ERROR');
    }
  } finally {
    isLoading.value = false;
  }
};

const toggleSummary = async () => {
  if (isExpanded.value) {
    isExpanded.value = false;
    return;
  }
  isExpanded.value = true;
  useTrack(CAPTAIN_EVENTS.SUMMARIZE_USED, {
    conversationId: props.chat.id,
    uiFrom: 'conversation_list',
  });
  // Only fetch if no cached summary
  if (!cachedSummary.value && !error.value) {
    await fetchSummary();
  }
};

const onButtonClick = e => {
  e.stopPropagation();
  toggleSummary();
};

defineExpose({
  isExpanded,
  isLoading,
  error,
  formattedSummary,
  captainTasksEnabled,
  isStale,
});
</script>

<template>
  <Button
    v-if="captainTasksEnabled"
    icon="i-material-symbols-auto-awesome"
    slate
    ghost
    xs
    :title="t('CHAT_LIST.SUMMARY.TITLE')"
    class="opacity-0 group-hover:opacity-100 transition-opacity"
    :class="{ '!opacity-100': isExpanded }"
    @click="onButtonClick"
  />
</template>
