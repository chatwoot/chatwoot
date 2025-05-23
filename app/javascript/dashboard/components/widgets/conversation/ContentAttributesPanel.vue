<script setup>
import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useRoute } from 'vue-router';
import NextButton from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const store = useStore();
const getters = useStoreGetters();
const route = useRoute();

const conversationId = computed(() => {
  return route.params.conversationId || getters.getSelectedChat.value.id;
});

const currentChat = computed(() => getters.getSelectedChat.value);

// Extract content attributes
const contentAttributes = computed(() => {
  if (!currentChat.value || !currentChat.value.content_attributes) {
    return null;
  }
  
  return currentChat.value.content_attributes;
});

// Computed properties for each section of content attributes
const messageCount = computed(() => contentAttributes.value?.message_count || null);
const responseTimes = computed(() => contentAttributes.value?.response_times || null);
const sentiment = computed(() => contentAttributes.value?.sentiment || null);
const topics = computed(() => contentAttributes.value?.topics || []);
const language = computed(() => contentAttributes.value?.language || null);
const complexity = computed(() => contentAttributes.value?.complexity || null);
const engagementMetrics = computed(() => contentAttributes.value?.engagement_metrics || null);
const conversationSummary = computed(() => contentAttributes.value?.conversation_summary || null);
const keyPhrases = computed(() => contentAttributes.value?.key_phrases || []);
const resolutionStatus = computed(() => contentAttributes.value?.resolution_status || null);

// Function to format sentiment for display
const formatSentiment = (sentiment) => {
  if (!sentiment) return '-';
  
  const sentimentMap = {
    very_positive: { label: t('CONVERSATION.CONTENT_ATTRIBUTES.SENTIMENT.VERY_POSITIVE'), color: 'text-green-800' },
    positive: { label: t('CONVERSATION.CONTENT_ATTRIBUTES.SENTIMENT.POSITIVE'), color: 'text-green-600' },
    neutral: { label: t('CONVERSATION.CONTENT_ATTRIBUTES.SENTIMENT.NEUTRAL'), color: 'text-slate-600' },
    negative: { label: t('CONVERSATION.CONTENT_ATTRIBUTES.SENTIMENT.NEGATIVE'), color: 'text-ruby-600' },
    very_negative: { label: t('CONVERSATION.CONTENT_ATTRIBUTES.SENTIMENT.VERY_NEGATIVE'), color: 'text-ruby-800' }
  };
  
  return sentimentMap[sentiment] || { label: sentiment, color: 'text-slate-600' };
};

// Format language for display
const formatLanguage = (lang) => {
  if (!lang) return '-';
  
  const languageMap = {
    english: t('CONVERSATION.CONTENT_ATTRIBUTES.LANGUAGE.ENGLISH'),
    spanish: t('CONVERSATION.CONTENT_ATTRIBUTES.LANGUAGE.SPANISH'),
    french: t('CONVERSATION.CONTENT_ATTRIBUTES.LANGUAGE.FRENCH'),
    german: t('CONVERSATION.CONTENT_ATTRIBUTES.LANGUAGE.GERMAN'),
    chinese: t('CONVERSATION.CONTENT_ATTRIBUTES.LANGUAGE.CHINESE'),
    japanese: t('CONVERSATION.CONTENT_ATTRIBUTES.LANGUAGE.JAPANESE'),
    unknown: t('CONVERSATION.CONTENT_ATTRIBUTES.LANGUAGE.UNKNOWN')
  };
  
  return languageMap[lang] || lang;
};

// Format resolution status
const formatResolutionStatus = (status) => {
  if (!status) return '-';
  
  const statusMap = {
    resolved: { label: t('CONVERSATION.CONTENT_ATTRIBUTES.RESOLUTION.RESOLVED'), color: 'text-green-800' },
    likely_resolved: { label: t('CONVERSATION.CONTENT_ATTRIBUTES.RESOLUTION.LIKELY_RESOLVED'), color: 'text-green-600' },
    unknown: { label: t('CONVERSATION.CONTENT_ATTRIBUTES.RESOLUTION.UNKNOWN'), color: 'text-slate-600' },
    likely_unresolved: { label: t('CONVERSATION.CONTENT_ATTRIBUTES.RESOLUTION.LIKELY_UNRESOLVED'), color: 'text-ruby-600' },
    unresolved: { label: t('CONVERSATION.CONTENT_ATTRIBUTES.RESOLUTION.UNRESOLVED'), color: 'text-ruby-800' }
  };
  
  return statusMap[status] || { label: status, color: 'text-slate-600' };
};

// Function to format seconds into readable duration
const formatDuration = (seconds) => {
  if (!seconds) return '-';
  
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const remainingSeconds = seconds % 60;
  
  if (hours > 0) {
    return `${hours}h ${minutes}m ${remainingSeconds}s`;
  } else if (minutes > 0) {
    return `${minutes}m ${remainingSeconds}s`;
  }
  
  return `${remainingSeconds}s`;
};

// Format complexity score (0-1) as a percentage and difficulty level
const formatComplexity = (score) => {
  if (score === null || score === undefined) return '-';
  
  const percentage = Math.round(score * 100);
  let level;
  
  if (score < 0.2) {
    level = t('CONVERSATION.CONTENT_ATTRIBUTES.COMPLEXITY.VERY_SIMPLE');
  } else if (score < 0.4) {
    level = t('CONVERSATION.CONTENT_ATTRIBUTES.COMPLEXITY.SIMPLE');
  } else if (score < 0.6) {
    level = t('CONVERSATION.CONTENT_ATTRIBUTES.COMPLEXITY.MEDIUM');
  } else if (score < 0.8) {
    level = t('CONVERSATION.CONTENT_ATTRIBUTES.COMPLEXITY.COMPLEX');
  } else {
    level = t('CONVERSATION.CONTENT_ATTRIBUTES.COMPLEXITY.VERY_COMPLEX');
  }
  
  return `${level} (${percentage}%)`;
};

// Function to force recalculation of content attributes
const refreshAttributes = () => {
  if (!conversationId.value) return;
  
  // Dispatch action to recalculate content attributes
  store.dispatch('conversations/updateContentAttributes', {
    conversationId: conversationId.value
  });
};

// Initialize content attributes if not present
onMounted(() => {
  if (currentChat.value && conversationId.value && 
      (!contentAttributes.value || Object.keys(contentAttributes.value).length === 0)) {
    refreshAttributes();
  }
});
</script>

<template>
  <div class="content-attributes-panel rounded-lg bg-white dark:bg-n-solid-1 p-4">
    <!-- Header with refresh button -->
    <div class="flex justify-between items-center mb-4">
      <h3 class="text-base font-medium">{{ $t('CONVERSATION.CONTENT_ATTRIBUTES.TITLE') }}</h3>
      <NextButton
        v-tooltip="$t('CONVERSATION.CONTENT_ATTRIBUTES.REFRESH')"
        xs
        ghost
        icon="i-lucide-refresh-cw"
        @click="refreshAttributes"
      />
    </div>
    
    <!-- Loading state -->
    <div v-if="!contentAttributes" class="p-3 text-center text-slate-600">
      {{ $t('CONVERSATION.CONTENT_ATTRIBUTES.LOADING') }}
    </div>
    
    <!-- Content when attributes are available -->
    <div v-else class="space-y-6">
      <!-- Conversation Summary -->
      <div v-if="conversationSummary" class="summary-section">
        <h4 class="text-sm font-medium mb-1">{{ $t('CONVERSATION.CONTENT_ATTRIBUTES.SUMMARY') }}</h4>
        <p class="text-sm text-slate-600 dark:text-slate-300">{{ conversationSummary }}</p>
      </div>
      
      <!-- Topics and Key Phrases -->
      <div class="flex flex-wrap gap-2">
        <!-- Topics tags -->
        <div v-if="topics && topics.length > 0" class="topics-section w-full">
          <h4 class="text-sm font-medium mb-1">{{ $t('CONVERSATION.CONTENT_ATTRIBUTES.TOPICS') }}</h4>
          <div class="flex flex-wrap gap-1">
            <span
              v-for="(topic, index) in topics"
              :key="`topic-${index}`"
              class="inline-block bg-n-slate-2 dark:bg-n-solid-2 px-2 py-1 rounded-md text-xs"
            >
              {{ topic }}
            </span>
          </div>
        </div>
        
        <!-- Key phrases -->
        <div v-if="keyPhrases && keyPhrases.length > 0" class="key-phrases-section w-full">
          <h4 class="text-sm font-medium mb-1">{{ $t('CONVERSATION.CONTENT_ATTRIBUTES.KEY_PHRASES') }}</h4>
          <div class="flex flex-wrap gap-1">
            <span
              v-for="(phrase, index) in keyPhrases"
              :key="`phrase-${index}`"
              class="inline-block bg-n-sky-2 dark:bg-n-indigo-1 dark:text-indigo-900 px-2 py-1 rounded-md text-xs"
            >
              {{ phrase }}
            </span>
          </div>
        </div>
      </div>
      
      <!-- Stats Dashboard -->
      <div class="stats-dashboard grid grid-cols-2 gap-3">
        <!-- Message count -->
        <div v-if="messageCount" class="stat-card p-2 bg-n-slate-1 dark:bg-n-solid-2 rounded-md">
          <h5 class="text-xs text-slate-500 dark:text-slate-400">{{ $t('CONVERSATION.CONTENT_ATTRIBUTES.MESSAGE_COUNT') }}</h5>
          <div class="flex justify-between items-center">
            <span class="text-lg font-medium">{{ messageCount.total }}</span>
            <div class="text-xs text-slate-500 dark:text-slate-400">
              <div>{{ $t('CONVERSATION.CONTENT_ATTRIBUTES.USER') }}: {{ messageCount.user }}</div>
              <div>{{ $t('CONVERSATION.CONTENT_ATTRIBUTES.AGENT') }}: {{ messageCount.agent }}</div>
            </div>
          </div>
        </div>
        
        <!-- Avg Response Time -->
        <div v-if="responseTimes && responseTimes.average" class="stat-card p-2 bg-n-slate-1 dark:bg-n-solid-2 rounded-md">
          <h5 class="text-xs text-slate-500 dark:text-slate-400">{{ $t('CONVERSATION.CONTENT_ATTRIBUTES.AVG_RESPONSE_TIME') }}</h5>
          <div class="flex items-center">
            <span class="text-lg font-medium">{{ formatDuration(responseTimes.average) }}</span>
          </div>
        </div>
        
        <!-- Sentiment -->
        <div v-if="sentiment" class="stat-card p-2 bg-n-slate-1 dark:bg-n-solid-2 rounded-md">
          <h5 class="text-xs text-slate-500 dark:text-slate-400">{{ $t('CONVERSATION.CONTENT_ATTRIBUTES.SENTIMENT') }}</h5>
          <div class="flex items-center">
            <span class="text-lg font-medium" :class="formatSentiment(sentiment).color">
              {{ formatSentiment(sentiment).label }}
            </span>
          </div>
        </div>
        
        <!-- Complexity -->
        <div v-if="complexity !== null" class="stat-card p-2 bg-n-slate-1 dark:bg-n-solid-2 rounded-md">
          <h5 class="text-xs text-slate-500 dark:text-slate-400">{{ $t('CONVERSATION.CONTENT_ATTRIBUTES.COMPLEXITY') }}</h5>
          <div class="flex items-center">
            <span class="text-lg font-medium">{{ formatComplexity(complexity) }}</span>
          </div>
        </div>
        
        <!-- Language -->
        <div v-if="language" class="stat-card p-2 bg-n-slate-1 dark:bg-n-solid-2 rounded-md">
          <h5 class="text-xs text-slate-500 dark:text-slate-400">{{ $t('CONVERSATION.CONTENT_ATTRIBUTES.LANGUAGE') }}</h5>
          <div class="flex items-center">
            <span class="text-lg font-medium">{{ formatLanguage(language) }}</span>
          </div>
        </div>
        
        <!-- Resolution Status -->
        <div v-if="resolutionStatus" class="stat-card p-2 bg-n-slate-1 dark:bg-n-solid-2 rounded-md">
          <h5 class="text-xs text-slate-500 dark:text-slate-400">{{ $t('CONVERSATION.CONTENT_ATTRIBUTES.RESOLUTION_STATUS') }}</h5>
          <div class="flex items-center">
            <span class="text-lg font-medium" :class="formatResolutionStatus(resolutionStatus).color">
              {{ formatResolutionStatus(resolutionStatus).label }}
            </span>
          </div>
        </div>
      </div>
      
      <!-- Engagement Metrics -->
      <div v-if="engagementMetrics" class="engagement-section">
        <h4 class="text-sm font-medium mb-1">{{ $t('CONVERSATION.CONTENT_ATTRIBUTES.ENGAGEMENT') }}</h4>
        <div class="grid grid-cols-2 gap-2">
          <div class="p-2 bg-n-slate-1 dark:bg-n-solid-2 rounded-md">
            <span class="text-xs text-slate-500 dark:text-slate-400">{{ $t('CONVERSATION.CONTENT_ATTRIBUTES.DURATION') }}</span>
            <div class="text-base font-medium">{{ formatDuration(engagementMetrics.duration_seconds) }}</div>
          </div>
          <div class="p-2 bg-n-slate-1 dark:bg-n-solid-2 rounded-md">
            <span class="text-xs text-slate-500 dark:text-slate-400">{{ $t('CONVERSATION.CONTENT_ATTRIBUTES.ENGAGEMENT_SCORE') }}</span>
            <div class="text-base font-medium">{{ (engagementMetrics.engagement_score * 100).toFixed(0) }}%</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.content-attributes-panel {
  max-height: 100%;
  overflow-y: auto;
}
</style> 