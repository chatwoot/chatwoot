<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import TasksAPI from 'dashboard/api/captain/tasks';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { useTrack } from 'dashboard/composables';
import { CAPTAIN_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();
const { isCloudFeatureEnabled } = useAccount();
const { formatMessage } = useMessageFormatter();

const currentChat = useMapGetter('getSelectedChat');
const isLoading = ref(false);
const error = ref('');

const captainTasksEnabled = computed(() => {
  return isCloudFeatureEnabled(FEATURE_FLAGS.CAPTAIN_TASKS);
});

const cachedSummary = computed(() => currentChat.value?.cached_summary || '');
const cachedSummaryAt = computed(
  () => currentChat.value?.cached_summary_at || 0
);
const lastActivityAt = computed(() => currentChat.value?.last_activity_at || 0);
const uiFrom = 'conversation_sidebar';

const isStale = computed(() => {
  if (!cachedSummaryAt.value) return true;
  return lastActivityAt.value > cachedSummaryAt.value;
});

const hasSummary = computed(() => !!cachedSummary.value);

const formattedSummary = computed(() => {
  return cachedSummary.value ? formatMessage(cachedSummary.value) : '';
});

const fetchSummary = async (forceRegenerate = false) => {
  if (!captainTasksEnabled.value) return;

  isLoading.value = true;
  error.value = '';

  try {
    const result = await TasksAPI.summarize(props.conversationId, {
      forceRegenerate,
    });
    const {
      data: { message: generatedSummary },
    } = result;

    if (generatedSummary) {
      store.dispatch('updateConversationCachedSummary', {
        conversationId: currentChat.value.id,
        cachedSummary: generatedSummary,
        cachedSummaryAt: Math.floor(Date.now() / 1000),
      });
    }
  } catch (e) {
    if (e.name !== 'AbortError' && e.name !== 'CanceledError') {
      error.value =
        e.response?.data?.error || t('CONVERSATION_SIDEBAR.SUMMARY.ERROR');
    }
  } finally {
    isLoading.value = false;
  }
};

const trackSummary = action => {
  useTrack(CAPTAIN_EVENTS.SUMMARIZE_USED, {
    conversationId: props.conversationId,
    uiFrom,
    action,
  });
};

const generateSummary = () => {
  trackSummary('generate');
  return fetchSummary(false);
};

const regenerate = () => {
  trackSummary('regenerate');
  return fetchSummary(true);
};

const retryGenerate = () => {
  trackSummary('retry');
  return fetchSummary(true);
};

watch(
  () => props.conversationId,
  () => {
    error.value = '';
  }
);

defineExpose({
  fetchSummary,
  captainTasksEnabled,
  cachedSummary,
  isStale,
});
</script>

<template>
  <div v-if="captainTasksEnabled" class="p-3">
    <div v-if="isLoading" class="flex items-center justify-center py-4">
      <Spinner :size="20" class="text-n-slate-10" />
    </div>

    <div v-else-if="error" class="text-sm text-n-ruby-11">
      {{ error }}
      <Button
        :label="t('CONVERSATION_SIDEBAR.SUMMARY.RETRY')"
        size="sm"
        variant="link"
        class="ml-2"
        @click="retryGenerate"
      />
    </div>

    <div v-else-if="!hasSummary" class="flex flex-col items-center gap-3 py-2">
      <p class="text-sm text-n-slate-11 text-center mb-0">
        {{ t('CONVERSATION_SIDEBAR.SUMMARY.DESCRIPTION') }}
      </p>
      <Button
        :label="t('CONVERSATION_SIDEBAR.SUMMARY.GENERATE')"
        icon="i-material-symbols-auto-awesome"
        size="sm"
        @click="generateSummary"
      />
    </div>

    <template v-else>
      <div
        v-if="isStale"
        class="flex items-center gap-2 mb-2 text-xs text-n-amber-11"
      >
        <span>{{ t('CONVERSATION_SIDEBAR.SUMMARY.STALE') }}</span>
        <Button
          :label="t('CONVERSATION_SIDEBAR.SUMMARY.REFRESH')"
          size="xs"
          variant="link"
          @click="regenerate"
        />
      </div>
      <div
        class="summary-content text-sm text-n-slate-11 [&_ul]:list-disc [&_ul]:pl-4 [&_ol]:list-decimal [&_ol]:pl-4 [&_li]:my-1 [&_p]:my-2 [&_p:first-child]:mt-0 [&_p:last-child]:mb-0 [&_strong]:text-n-slate-12"
        v-html="formattedSummary"
      />
      <div class="mt-3 pt-3 border-t border-n-weak">
        <Button
          :label="t('CONVERSATION_SIDEBAR.SUMMARY.REGENERATE')"
          icon="i-lucide-refresh-cw"
          size="sm"
          variant="faded"
          color="slate"
          @click="regenerate"
        />
      </div>
    </template>
  </div>
</template>
