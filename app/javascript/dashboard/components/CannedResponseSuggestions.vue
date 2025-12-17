<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  conversationId: {
    type: [String, Number],
    required: true,
  },
  contactId: {
    type: [String, Number],
    default: null,
  },
  lastMessage: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['use-suggestion', 'close']);

const { t } = useI18n();
const store = useStore();

const suggestions = ref([]);
const loading = ref(false);
const error = ref(null);
const feedbackSubmitted = ref({});

const accountId = useMapGetter('getCurrentAccountId');

const loadSuggestions = async () => {
  if (!props.conversationId) return;

  loading.value = true;
  error.value = null;

  try {
    const response = await store.dispatch('cannedResponses/fetchSuggestions', {
      accountId: accountId.value,
      conversationId: props.conversationId,
      limit: 5,
    });

    suggestions.value = response.data || [];
  } catch (err) {
    console.error('Failed to load canned response suggestions:', err);
    error.value = t('CANNED_RESPONSE_SUGGESTIONS.ERROR');
  } finally {
    loading.value = false;
  }
};

const useSuggestion = (suggestion) => {
  emit('use-suggestion', {
    content: suggestion.content,
    shortCode: suggestion.short_code,
    suggestionId: suggestion.id,
  });

  // Track usage analytics
  store.dispatch('analytics/track', {
    event: 'canned_response_suggestion_used',
    properties: {
      suggestion_id: suggestion.id,
      conversation_id: props.conversationId,
    },
  });
};

const submitFeedback = async (suggestion, rating) => {
  const feedbackKey = `${suggestion.id}_${rating}`;

  if (feedbackSubmitted.value[feedbackKey]) {
    return;
  }

  try {
    await store.dispatch('rlhf/submitFeedback', {
      accountId: accountId.value,
      feedbackData: {
        suggestion_type: 'canned_response_suggestion',
        suggestion_id: suggestion.id,
        conversation_id: props.conversationId,
        prompt: props.lastMessage,
        response: suggestion.content,
        rating: rating,
        metadata: {
          short_code: suggestion.short_code,
          contact_id: props.contactId,
        },
      },
    });

    feedbackSubmitted.value[feedbackKey] = true;
    useAlert(t('CANNED_RESPONSE_SUGGESTIONS.FEEDBACK_SUCCESS'));
  } catch (err) {
    console.error('Failed to submit feedback:', err);
    useAlert(t('CANNED_RESPONSE_SUGGESTIONS.FEEDBACK_ERROR'));
  }
};

const refreshSuggestions = () => {
  suggestions.value = [];
  feedbackSubmitted.value = {};
  loadSuggestions();
};

const hasSuggestions = computed(() => suggestions.value.length > 0);

onMounted(() => {
  loadSuggestions();
});

watch(() => props.conversationId, () => {
  loadSuggestions();
});

watch(() => props.lastMessage, () => {
  // Debounce refresh on new messages
  if (props.lastMessage) {
    setTimeout(refreshSuggestions, 2000);
  }
});
</script>

<template>
  <div class="canned-response-suggestions">
    <div class="suggestions-header">
      <div class="header-content">
        <span class="header-icon">💡</span>
        <div class="header-text">
          <h4 class="header-title">{{ t('CANNED_RESPONSE_SUGGESTIONS.TITLE') }}</h4>
          <p class="header-subtitle">{{ t('CANNED_RESPONSE_SUGGESTIONS.SUBTITLE') }}</p>
        </div>
      </div>
      <button
        v-if="!loading"
        class="refresh-button"
        :aria-label="t('CANNED_RESPONSE_SUGGESTIONS.REFRESH')"
        @click="refreshSuggestions"
      >
        <fluent-icon icon="arrow-clockwise" size="16" />
      </button>
    </div>

    <div class="powered-by-badge">
      <span class="badge-icon">✨</span>
      <span class="badge-text">Powered by ZeroDB AI</span>
    </div>

    <div v-if="loading" class="loading-state">
      <Spinner size="small" />
      <p class="loading-text">{{ t('CANNED_RESPONSE_SUGGESTIONS.LOADING') }}</p>
    </div>

    <div v-else-if="error" class="error-state">
      <fluent-icon icon="error-circle" size="24" class="error-icon" />
      <p class="error-message">{{ error }}</p>
      <button class="retry-button" @click="refreshSuggestions">
        {{ t('CANNED_RESPONSE_SUGGESTIONS.RETRY') }}
      </button>
    </div>

    <div v-else-if="hasSuggestions" class="suggestions-list">
      <div
        v-for="suggestion in suggestions"
        :key="suggestion.id"
        class="suggestion-card"
        role="article"
        :aria-label="`Suggestion: ${suggestion.short_code}`"
      >
        <div class="suggestion-header">
          <span class="short-code" :title="suggestion.short_code">
            /{{ suggestion.short_code }}
          </span>
          <button
            class="use-button"
            :aria-label="`Use ${suggestion.short_code}`"
            @click="useSuggestion(suggestion)"
          >
            {{ t('CANNED_RESPONSE_SUGGESTIONS.USE') }}
          </button>
        </div>

        <p class="suggestion-content">{{ suggestion.content }}</p>

        <div v-if="suggestion.similarity_score" class="similarity-indicator">
          <div class="similarity-bar">
            <div
              class="similarity-fill"
              :style="{ width: `${suggestion.similarity_score * 100}%` }"
            />
          </div>
          <span class="similarity-text">
            {{ Math.round(suggestion.similarity_score * 100) }}% relevant
          </span>
        </div>

        <div class="feedback-section">
          <span class="feedback-label">{{ t('CANNED_RESPONSE_SUGGESTIONS.HELPFUL') }}</span>
          <div class="feedback-buttons">
            <button
              class="feedback-button thumbs-up"
              :class="{ active: feedbackSubmitted[`${suggestion.id}_5`] }"
              :disabled="feedbackSubmitted[`${suggestion.id}_5`]"
              :aria-label="t('CANNED_RESPONSE_SUGGESTIONS.THUMBS_UP')"
              @click="submitFeedback(suggestion, 5)"
            >
              👍
            </button>
            <button
              class="feedback-button thumbs-down"
              :class="{ active: feedbackSubmitted[`${suggestion.id}_1`] }"
              :disabled="feedbackSubmitted[`${suggestion.id}_1`]"
              :aria-label="t('CANNED_RESPONSE_SUGGESTIONS.THUMBS_DOWN')"
              @click="submitFeedback(suggestion, 1)"
            >
              👎
            </button>
          </div>
        </div>
      </div>
    </div>

    <div v-else class="empty-state">
      <fluent-icon icon="lightbulb" size="32" class="empty-icon" />
      <p class="empty-message">{{ t('CANNED_RESPONSE_SUGGESTIONS.EMPTY') }}</p>
      <p class="empty-hint">{{ t('CANNED_RESPONSE_SUGGESTIONS.EMPTY_HINT') }}</p>
    </div>
  </div>
</template>

<style scoped lang="scss">
.canned-response-suggestions {
  display: flex;
  flex-direction: column;
  background-color: var(--color-background-light);
  border-radius: var(--border-radius-normal);
  padding: var(--space-normal);
  gap: var(--space-small);
  height: 100%;
}

.suggestions-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: var(--space-small);
}

.header-content {
  display: flex;
  align-items: flex-start;
  gap: var(--space-small);
  flex: 1;
}

.header-icon {
  font-size: var(--font-size-large);
  line-height: 1;
}

.header-text {
  flex: 1;
}

.header-title {
  font-size: var(--font-size-default);
  font-weight: var(--font-weight-medium);
  color: var(--color-body);
  margin: 0 0 var(--space-micro);
}

.header-subtitle {
  font-size: var(--font-size-mini);
  color: var(--color-light-gray);
  margin: 0;
  line-height: 1.4;
}

.refresh-button {
  background: none;
  border: none;
  color: var(--color-light-gray);
  cursor: pointer;
  padding: var(--space-micro);
  border-radius: var(--border-radius-small);
  transition: all 0.2s ease;
  display: flex;
  align-items: center;

  &:hover {
    background-color: var(--color-background);
    color: var(--w-500);
  }

  &:focus {
    outline: 2px solid var(--w-500);
    outline-offset: 2px;
  }
}

.powered-by-badge {
  display: inline-flex;
  align-items: center;
  gap: var(--space-micro);
  padding: var(--space-micro) var(--space-small);
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: var(--white);
  border-radius: var(--border-radius-large);
  font-size: 10px;
  font-weight: var(--font-weight-medium);
  box-shadow: 0 2px 4px rgba(102, 126, 234, 0.2);
  align-self: flex-start;
}

.badge-icon {
  font-size: 11px;
}

.loading-state,
.error-state,
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: var(--space-large);
  text-align: center;
}

.loading-text {
  margin-top: var(--space-small);
  font-size: var(--font-size-small);
  color: var(--color-light-gray);
}

.error-icon {
  color: var(--r-500);
  margin-bottom: var(--space-small);
}

.error-message {
  font-size: var(--font-size-small);
  color: var(--color-body);
  margin: 0 0 var(--space-normal);
}

.retry-button {
  padding: var(--space-smaller) var(--space-normal);
  background-color: var(--w-500);
  color: var(--white);
  border: none;
  border-radius: var(--border-radius-normal);
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-medium);
  cursor: pointer;
  transition: background-color 0.2s ease;

  &:hover {
    background-color: var(--w-600);
  }

  &:focus {
    outline: 2px solid var(--w-500);
    outline-offset: 2px;
  }
}

.suggestions-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-small);
  overflow-y: auto;
  flex: 1;
}

.suggestion-card {
  background-color: var(--white);
  border: 1px solid var(--color-border-light);
  border-radius: var(--border-radius-normal);
  padding: var(--space-normal);
  transition: all 0.2s ease;

  &:hover {
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
    border-color: var(--w-300);
  }

  &:focus-within {
    border-color: var(--w-500);
  }
}

.suggestion-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: var(--space-small);
}

.short-code {
  font-family: var(--font-family-monospace);
  font-size: var(--font-size-mini);
  color: var(--w-700);
  background-color: var(--w-50);
  padding: var(--space-micro) var(--space-smaller);
  border-radius: var(--border-radius-small);
  font-weight: var(--font-weight-medium);
  max-width: 150px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.use-button {
  padding: var(--space-micro) var(--space-small);
  background-color: var(--w-500);
  color: var(--white);
  border: none;
  border-radius: var(--border-radius-small);
  font-size: var(--font-size-mini);
  font-weight: var(--font-weight-medium);
  cursor: pointer;
  transition: all 0.2s ease;

  &:hover {
    background-color: var(--w-600);
    transform: translateY(-1px);
  }

  &:active {
    transform: translateY(0);
  }

  &:focus {
    outline: 2px solid var(--w-500);
    outline-offset: 2px;
  }
}

.suggestion-content {
  font-size: var(--font-size-small);
  color: var(--color-body);
  line-height: 1.5;
  margin: 0 0 var(--space-small);
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.similarity-indicator {
  display: flex;
  align-items: center;
  gap: var(--space-small);
  margin-bottom: var(--space-small);
}

.similarity-bar {
  flex: 1;
  height: 4px;
  background-color: var(--color-border-light);
  border-radius: var(--border-radius-small);
  overflow: hidden;
}

.similarity-fill {
  height: 100%;
  background: linear-gradient(90deg, var(--g-400), var(--g-600));
  border-radius: var(--border-radius-small);
  transition: width 0.3s ease;
}

.similarity-text {
  font-size: var(--font-size-mini);
  color: var(--color-light-gray);
  white-space: nowrap;
}

.feedback-section {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding-top: var(--space-small);
  border-top: 1px solid var(--color-border-light);
}

.feedback-label {
  font-size: var(--font-size-mini);
  color: var(--color-light-gray);
}

.feedback-buttons {
  display: flex;
  gap: var(--space-smaller);
}

.feedback-button {
  background: none;
  border: 1px solid var(--color-border);
  border-radius: var(--border-radius-small);
  padding: var(--space-micro) var(--space-small);
  font-size: var(--font-size-default);
  cursor: pointer;
  transition: all 0.2s ease;
  opacity: 0.6;

  &:hover:not(:disabled) {
    opacity: 1;
    transform: scale(1.1);
  }

  &:disabled {
    cursor: not-allowed;
  }

  &.active {
    opacity: 1;
    border-color: var(--g-500);
    background-color: var(--g-50);
  }

  &:focus {
    outline: 2px solid var(--w-500);
    outline-offset: 2px;
  }
}

.empty-icon {
  color: var(--color-light-gray);
  margin-bottom: var(--space-small);
}

.empty-message {
  font-size: var(--font-size-small);
  color: var(--color-body);
  margin: 0 0 var(--space-micro);
}

.empty-hint {
  font-size: var(--font-size-mini);
  color: var(--color-light-gray);
  margin: 0;
}

/* Mobile responsive styles */
@media screen and (max-width: 768px) {
  .canned-response-suggestions {
    padding: var(--space-small);
  }

  .suggestion-card {
    padding: var(--space-small);
  }

  .short-code {
    max-width: 100px;
  }
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  .suggestion-card {
    background-color: var(--color-background);
    border-color: var(--color-border);
  }

  .short-code {
    background-color: var(--color-background-light);
    color: var(--w-300);
  }
}
</style>
