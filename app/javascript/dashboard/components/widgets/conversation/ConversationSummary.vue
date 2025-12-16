<script setup>
import { ref, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import ConversationApi from 'dashboard/api/conversations';
import Spinner from 'shared/components/Spinner.vue';
import MarkdownIt from 'markdown-it';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const { t } = useI18n();
const md = new MarkdownIt();

const summary = ref('');
const isLoading = ref(false);
const isError = ref(false);
const lastUpdated = ref('');
const lastGeneratedAt = ref(null);

// Helper function to format timestamp
const formatTimestamp = (timestamp) => {
  if (!timestamp) return '';
  const date = new Date(timestamp);
  const options = {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: true
  };
  return date.toLocaleString('en-US', options).replace(',', '');
};

const isRateLimited = () => {
  if (!lastGeneratedAt.value) return false;
  const lastTime = new Date(lastGeneratedAt.value).getTime();
  return (Date.now() - lastTime) < 24 * 60 * 60 * 1000;
};

const fetchSummary = async (forceRefresh = false) => {
  if (!props.conversationId) return;

  const shouldShowLoader = !summary.value || (forceRefresh && !isRateLimited());

  if (shouldShowLoader) {
    isLoading.value = true;
  }
  isError.value = false;
  try {
    const response = await ConversationApi.getSummary(props.conversationId, forceRefresh);
    summary.value = response.data.summary;

    // Check for backend alert message (force refresh rate limit)
    if (response.data.alert_message) {
      useAlert(response.data.alert_message);
    }
    
    // Update local state for rate limiting check
    if (response.data.last_generated_at) {
      lastGeneratedAt.value = response.data.last_generated_at;
    }

    // Use the timestamp from the backend (database)
    if (response.data.updated_at) {
      lastUpdated.value = formatTimestamp(response.data.updated_at);
    } else {
      // Fallback to current time for display if not provided
      const now = new Date();
      lastUpdated.value = formatTimestamp(now);
    }
  } catch (error) {
    isError.value = true;
  } finally {
    isLoading.value = false;
  }
};


watch(
  () => props.conversationId,
  (newId, oldId) => {
    // Clear previous summary when switching conversations
    if (newId !== oldId) {
      summary.value = '';
      lastUpdated.value = '';
    }
    fetchSummary();
  },
  { immediate: true }
);

defineExpose({
  fetchSummary,
});
</script>

<template>
  <div class="px-4 py-4 h-full bg-n-background relative">
    <div
      v-if="isLoading"
      class="flex flex-col items-center justify-center p-8 h-full"
    >
      <Spinner />
      <span class="mt-4 text-sm text-n-slate-11">
        {{ t('CONVERSATION.SUMMARY.LOADING_MESSAGE') }}
      </span>
    </div>
    <div
      v-else-if="isError"
      class="flex flex-col items-center justify-center h-full p-6 text-center"
    >
      <p class="text-n-slate-11 text-sm mb-3">
        {{ t('CONVERSATION.SUMMARY.ERROR') }}
      </p>
      <button
        class="text-sm font-medium text-woot-500 hover:text-woot-600 transition-colors"
        @click="fetchSummary"
      >
        {{ t('CONVERSATION.SUMMARY.RETRY') }}
      </button>
    </div>
    <div
      v-else-if="!summary"
      class="flex items-center justify-center h-full p-6"
    >
      <p class="text-n-slate-11 text-sm text-center">
        {{ t('CONVERSATION.SUMMARY.EMPTY') }}
      </p>
    </div>
    <div v-else>
      <!-- Timestamp -->
      <div class="mb-3">
        <p class="text-xs text-n-slate-11">
          {{ t('CONVERSATION.SUMMARY.LAST_UPDATED', { timestamp: lastUpdated }) }}
        </p>
      </div>
      
      <!-- Summary Content -->
      <div
        class="bg-n-solid-2 rounded-xl p-4 min-h-[200px] border border-n-weak"
      >
        <div
          class="prose prose-sm dark:prose-invert max-w-none text-n-slate-11 leading-relaxed text-sm font-normal break-words"
          v-html="md.render(summary)"
        />
      </div>
    </div>
  </div>
</template>
