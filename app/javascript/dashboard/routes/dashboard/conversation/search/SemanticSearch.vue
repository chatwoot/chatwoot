<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { debounce } from 'lodash';
import ConversationCard from '../../components/widgets/conversation/ConversationCard.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';

const props = defineProps({
  conversationInbox: { type: [String, Number], default: 0 },
  teamId: { type: [String, Number], default: 0 },
});

const { t } = useI18n();
const store = useStore();
const router = useRouter();

const searchQuery = ref('');
const results = ref([]);
const loading = ref(false);
const hasSearched = ref(false);

const accountId = useMapGetter('getCurrentAccountId');

const performSemanticSearch = async () => {
  if (searchQuery.value.trim().length < 3) {
    results.value = [];
    hasSearched.value = false;
    return;
  }

  loading.value = true;
  hasSearched.value = true;

  try {
    const response = await store.dispatch('conversations/searchSemantic', {
      accountId: accountId.value,
      query: searchQuery.value,
      limit: 20,
      inbox_id: props.conversationInbox || undefined,
      team_id: props.teamId || undefined,
    });

    results.value = response.data || [];
  } catch (error) {
    console.error('Semantic search failed:', error);
    useAlert(t('SEMANTIC_SEARCH.ERROR'));
    results.value = [];
  } finally {
    loading.value = false;
  }
};

const debouncedSearch = debounce(performSemanticSearch, 500);

const handleInput = () => {
  debouncedSearch();
};

const handleClearSearch = () => {
  searchQuery.value = '';
  results.value = [];
  hasSearched.value = false;
};

const selectConversation = (conversation) => {
  router.push({
    name: 'inbox_conversation',
    params: {
      accountId: accountId.value,
      conversationId: conversation.id,
    },
  });
};

const showEmptyState = computed(() => {
  return hasSearched.value && !loading.value && results.value.length === 0;
});

const showResults = computed(() => {
  return hasSearched.value && !loading.value && results.value.length > 0;
});
</script>

<template>
  <div class="semantic-search-container">
    <div class="search-header">
      <h2 class="page-title">
        {{ t('SEMANTIC_SEARCH.TITLE') }}
      </h2>
      <p class="page-subtitle">
        {{ t('SEMANTIC_SEARCH.SUBTITLE') }}
      </p>
    </div>

    <div class="search-input-wrapper">
      <div class="search-input-container">
        <span class="search-icon">
          <fluent-icon icon="search" size="20" />
        </span>
        <input
          v-model="searchQuery"
          type="text"
          :placeholder="t('SEMANTIC_SEARCH.PLACEHOLDER')"
          class="search-input"
          aria-label="Semantic search input"
          @input="handleInput"
          @keyup.escape="handleClearSearch"
        />
        <button
          v-if="searchQuery"
          class="clear-button"
          :aria-label="t('SEMANTIC_SEARCH.CLEAR')"
          @click="handleClearSearch"
        >
          <fluent-icon icon="dismiss" size="16" />
        </button>
      </div>
      <div class="powered-by-badge">
        <span class="badge-icon">✨</span>
        <span class="badge-text">Powered by ZeroDB AI</span>
      </div>
    </div>

    <div v-if="loading" class="loading-container">
      <Spinner />
      <p class="loading-text">{{ t('SEMANTIC_SEARCH.SEARCHING') }}</p>
    </div>

    <div v-if="showResults" class="results-container">
      <div class="results-header">
        <h3 class="results-count">
          {{ t('SEMANTIC_SEARCH.RESULTS_COUNT', { count: results.length }) }}
        </h3>
        <p class="results-description">
          {{ t('SEMANTIC_SEARCH.RESULTS_DESCRIPTION') }}
        </p>
      </div>

      <div class="conversation-list" role="list">
        <div
          v-for="conversation in results"
          :key="conversation.id"
          class="conversation-item"
          role="listitem"
        >
          <ConversationCard
            :chat="conversation"
            :hide-inbox-name="false"
            :show-assignee="true"
            @click="selectConversation(conversation)"
          />
          <div v-if="conversation.similarity_score" class="similarity-badge">
            {{ Math.round(conversation.similarity_score * 100) }}% match
          </div>
        </div>
      </div>
    </div>

    <EmptyStateLayout
      v-if="showEmptyState"
      :title="t('SEMANTIC_SEARCH.EMPTY_STATE.TITLE')"
      :message="t('SEMANTIC_SEARCH.EMPTY_STATE.MESSAGE')"
      icon="search"
    />

    <div v-if="!hasSearched && !loading" class="initial-state">
      <div class="initial-state-icon">
        <fluent-icon icon="lightbulb" size="48" />
      </div>
      <h3 class="initial-state-title">
        {{ t('SEMANTIC_SEARCH.INITIAL_STATE.TITLE') }}
      </h3>
      <p class="initial-state-message">
        {{ t('SEMANTIC_SEARCH.INITIAL_STATE.MESSAGE') }}
      </p>
      <div class="example-queries">
        <p class="example-header">{{ t('SEMANTIC_SEARCH.EXAMPLES.HEADER') }}</p>
        <ul class="example-list">
          <li>"Customer wants refund for damaged product"</li>
          <li>"Password reset issues"</li>
          <li>"Billing questions about subscription"</li>
          <li>"Feature requests for mobile app"</li>
        </ul>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.semantic-search-container {
  display: flex;
  flex-direction: column;
  height: 100%;
  padding: var(--space-normal);
  background-color: var(--color-background);
}

.search-header {
  margin-bottom: var(--space-normal);
}

.page-title {
  font-size: var(--font-size-large);
  font-weight: var(--font-weight-medium);
  color: var(--color-body);
  margin: 0 0 var(--space-smaller);
}

.page-subtitle {
  font-size: var(--font-size-small);
  color: var(--color-light-gray);
  margin: 0;
}

.search-input-wrapper {
  margin-bottom: var(--space-normal);
}

.search-input-container {
  position: relative;
  display: flex;
  align-items: center;
  margin-bottom: var(--space-smaller);
}

.search-icon {
  position: absolute;
  left: var(--space-small);
  color: var(--color-light-gray);
  pointer-events: none;
  display: flex;
  align-items: center;
}

.search-input {
  width: 100%;
  padding: var(--space-small) var(--space-large) var(--space-small) var(--space-larger);
  border: 1px solid var(--color-border);
  border-radius: var(--border-radius-normal);
  font-size: var(--font-size-default);
  background-color: var(--white);
  transition: all 0.2s ease;

  &:focus {
    outline: none;
    border-color: var(--w-500);
    box-shadow: 0 0 0 3px var(--w-100);
  }

  &::placeholder {
    color: var(--color-light-gray);
  }
}

.clear-button {
  position: absolute;
  right: var(--space-small);
  background: none;
  border: none;
  color: var(--color-light-gray);
  cursor: pointer;
  padding: var(--space-smaller);
  display: flex;
  align-items: center;
  border-radius: var(--border-radius-small);
  transition: background-color 0.2s ease;

  &:hover {
    background-color: var(--color-background-light);
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
  font-size: var(--font-size-mini);
  font-weight: var(--font-weight-medium);
  box-shadow: 0 2px 4px rgba(102, 126, 234, 0.2);
}

.badge-icon {
  font-size: var(--font-size-small);
}

.loading-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: var(--space-mega);
  gap: var(--space-normal);
}

.loading-text {
  color: var(--color-light-gray);
  font-size: var(--font-size-default);
}

.results-container {
  flex: 1;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.results-header {
  margin-bottom: var(--space-normal);
  padding-bottom: var(--space-small);
  border-bottom: 1px solid var(--color-border-light);
}

.results-count {
  font-size: var(--font-size-medium);
  font-weight: var(--font-weight-medium);
  color: var(--color-body);
  margin: 0 0 var(--space-micro);
}

.results-description {
  font-size: var(--font-size-small);
  color: var(--color-light-gray);
  margin: 0;
}

.conversation-list {
  flex: 1;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: var(--space-smaller);
}

.conversation-item {
  position: relative;
  background: var(--white);
  border: 1px solid var(--color-border-light);
  border-radius: var(--border-radius-normal);
  padding: var(--space-small);
  cursor: pointer;
  transition: all 0.2s ease;

  &:hover {
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
    border-color: var(--w-300);
  }

  &:focus-within {
    outline: 2px solid var(--w-500);
    outline-offset: 2px;
  }
}

.similarity-badge {
  position: absolute;
  top: var(--space-small);
  right: var(--space-small);
  padding: var(--space-micro) var(--space-small);
  background-color: var(--g-100);
  color: var(--g-800);
  font-size: var(--font-size-mini);
  font-weight: var(--font-weight-medium);
  border-radius: var(--border-radius-large);
}

.initial-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: var(--space-mega);
  text-align: center;
}

.initial-state-icon {
  color: var(--w-500);
  margin-bottom: var(--space-normal);
}

.initial-state-title {
  font-size: var(--font-size-large);
  font-weight: var(--font-weight-medium);
  color: var(--color-body);
  margin: 0 0 var(--space-small);
}

.initial-state-message {
  font-size: var(--font-size-default);
  color: var(--color-light-gray);
  margin: 0 0 var(--space-large);
  max-width: 500px;
}

.example-queries {
  text-align: left;
  background-color: var(--color-background-light);
  padding: var(--space-normal);
  border-radius: var(--border-radius-normal);
  max-width: 600px;
}

.example-header {
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-medium);
  color: var(--color-body);
  margin: 0 0 var(--space-small);
}

.example-list {
  list-style: none;
  padding: 0;
  margin: 0;

  li {
    padding: var(--space-smaller);
    font-size: var(--font-size-small);
    color: var(--color-light-gray);
    font-style: italic;

    &:before {
      content: '→';
      margin-right: var(--space-small);
      color: var(--w-500);
    }
  }
}

/* Mobile responsive styles */
@media screen and (max-width: 768px) {
  .semantic-search-container {
    padding: var(--space-small);
  }

  .page-title {
    font-size: var(--font-size-medium);
  }

  .search-input {
    font-size: var(--font-size-small);
  }

  .similarity-badge {
    position: static;
    margin-top: var(--space-smaller);
    display: inline-block;
  }

  .example-queries {
    padding: var(--space-small);
  }
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  .search-input {
    background-color: var(--color-background);
    color: var(--white);
  }

  .conversation-item {
    background-color: var(--color-background);
    border-color: var(--color-border);
  }
}
</style>
