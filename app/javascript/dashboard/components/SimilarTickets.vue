<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Label from 'dashboard/components/ui/Label.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
  maxResults: {
    type: Number,
    default: 5,
  },
});

const { t } = useI18n();
const store = useStore();
const router = useRouter();

const similarTickets = ref([]);
const loading = ref(false);
const error = ref(null);

const accountId = useMapGetter('getCurrentAccountId');

const loadSimilarTickets = async () => {
  if (!props.conversationId) return;

  loading.value = true;
  error.value = null;

  try {
    const response = await store.dispatch('conversations/fetchSimilar', {
      accountId: accountId.value,
      conversationId: props.conversationId,
      limit: props.maxResults,
    });

    similarTickets.value = response.data || [];
  } catch (err) {
    console.error('Failed to load similar tickets:', err);
    error.value = t('SIMILAR_TICKETS.ERROR.LOAD');
    useAlert(error.value);
    similarTickets.value = [];
  } finally {
    loading.value = false;
  }
};

const navigateToConversation = (conversation) => {
  router.push({
    name: 'inbox_conversation',
    params: {
      accountId: accountId.value,
      conversationId: conversation.id,
    },
  });
};

const getStatusClass = (status) => {
  const statusMap = {
    open: 'status-open',
    resolved: 'status-resolved',
    pending: 'status-pending',
    snoozed: 'status-snoozed',
  };
  return statusMap[status] || 'status-open';
};

const getStatusLabel = (status) => {
  const labels = {
    open: t('SIMILAR_TICKETS.STATUS.OPEN'),
    resolved: t('SIMILAR_TICKETS.STATUS.RESOLVED'),
    pending: t('SIMILAR_TICKETS.STATUS.PENDING'),
    snoozed: t('SIMILAR_TICKETS.STATUS.SNOOZED'),
  };
  return labels[status] || status;
};

const hasSimilarTickets = computed(() => similarTickets.value.length > 0);

watch(() => props.conversationId, () => {
  loadSimilarTickets();
}, { immediate: true });
</script>

<template>
  <div class="similar-tickets">
    <div class="tickets-header">
      <div class="header-content">
        <h4 class="header-title">
          <fluent-icon icon="document-multiple" size="16" />
          {{ t('SIMILAR_TICKETS.TITLE') }}
        </h4>
        <Label
          title="Powered by ZeroDB AI"
          color-scheme="primary"
          variant="smooth"
          small
          icon="sparkle"
        />
      </div>
      
      <p class="header-subtitle">{{ t('SIMILAR_TICKETS.SUBTITLE') }}</p>
    </div>

    <div v-if="loading" class="loading-container">
      <Spinner size="small" />
      <p class="loading-text">{{ t('SIMILAR_TICKETS.LOADING') }}</p>
    </div>

    <div v-else-if="error" class="error-container">
      <fluent-icon icon="error-circle" size="20" class="error-icon" />
      <p class="error-text">{{ error }}</p>
      <button class="retry-button" @click="loadSimilarTickets">
        {{ t('SIMILAR_TICKETS.RETRY') }}
      </button>
    </div>

    <div v-else-if="!hasSimilarTickets" class="empty-state">
      <fluent-icon icon="document-search" size="32" class="empty-icon" />
      <p class="empty-message">{{ t('SIMILAR_TICKETS.EMPTY_STATE') }}</p>
      <p class="empty-hint">{{ t('SIMILAR_TICKETS.EMPTY_HINT') }}</p>
    </div>

    <div v-else class="tickets-list" role="list">
      <article
        v-for="ticket in similarTickets"
        :key="ticket.id"
        class="ticket-item"
        role="listitem"
        tabindex="0"
        :aria-label="`Similar conversation #${ticket.id}`"
        @click="navigateToConversation(ticket)"
        @keyup.enter="navigateToConversation(ticket)"
      >
        <div class="ticket-header">
          <div class="ticket-meta">
            <span class="ticket-id">#{{ ticket.id }}</span>
            <span class="ticket-status" :class="getStatusClass(ticket.status)">
              {{ getStatusLabel(ticket.status) }}
            </span>
          </div>
          
          <div v-if="ticket.similarity_score" class="similarity-score">
            <div class="score-circle" :class="getSimilarityClass(ticket.similarity_score)">
              {{ Math.round(ticket.similarity_score * 100) }}%
            </div>
          </div>
        </div>

        <div class="ticket-content">
          <h5 v-if="ticket.subject" class="ticket-subject">
            {{ ticket.subject }}
          </h5>
          
          <p v-if="ticket.last_message" class="ticket-preview">
            {{ ticket.last_message }}
          </p>
        </div>

        <div class="ticket-footer">
          <div v-if="ticket.contact" class="ticket-contact">
            <fluent-icon icon="person" size="12" />
            <span class="contact-name">{{ ticket.contact.name }}</span>
          </div>
          
          <time v-if="ticket.created_at" class="ticket-date" :datetime="ticket.created_at">
            {{ formatDate(ticket.created_at) }}
          </time>
        </div>

        <div class="ticket-arrow">
          <fluent-icon icon="chevron-right" size="16" />
        </div>
      </article>
    </div>
  </div>
</template>

<script>
export default {
  methods: {
    formatDate(dateString) {
      const date = new Date(dateString);
      const now = new Date();
      const diff = now - date;
      const days = Math.floor(diff / (1000 * 60 * 60 * 24));

      if (days === 0) {
        return this.$t('SIMILAR_TICKETS.TIME.TODAY');
      } else if (days === 1) {
        return this.$t('SIMILAR_TICKETS.TIME.YESTERDAY');
      } else if (days < 7) {
        return this.$t('SIMILAR_TICKETS.TIME.DAYS_AGO', { count: days });
      } else {
        return date.toLocaleDateString();
      }
    },

    getSimilarityClass(score) {
      if (score >= 0.8) return 'high';
      if (score >= 0.6) return 'medium';
      return 'low';
    },
  },
};
</script>

<style scoped lang="scss">
.similar-tickets {
  display: flex;
  flex-direction: column;
  background-color: var(--white);
  border: 1px solid var(--color-border-light);
  border-radius: var(--border-radius-normal);
  padding: var(--space-normal);
  height: 100%;
}

.tickets-header {
  margin-bottom: var(--space-normal);
  padding-bottom: var(--space-small);
  border-bottom: 1px solid var(--color-border-light);
}

.header-content {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-small);
  margin-bottom: var(--space-small);
}

.header-title {
  display: flex;
  align-items: center;
  gap: var(--space-small);
  font-size: var(--font-size-default);
  font-weight: var(--font-weight-medium);
  color: var(--color-body);
  margin: 0;
}

.header-subtitle {
  font-size: var(--font-size-mini);
  color: var(--color-light-gray);
  margin: 0;
  line-height: 1.4;
}

.loading-container,
.error-container,
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

.error-text {
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

.tickets-list {
  flex: 1;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: var(--space-small);
}

.ticket-item {
  position: relative;
  background-color: var(--color-background-light);
  border: 1px solid var(--color-border-light);
  border-radius: var(--border-radius-normal);
  padding: var(--space-normal);
  padding-right: var(--space-mega);
  cursor: pointer;
  transition: all 0.2s ease;

  &:hover {
    border-color: var(--w-300);
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
    transform: translateX(2px);
  }

  &:focus {
    outline: 2px solid var(--w-500);
    outline-offset: 2px;
  }
}

.ticket-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: var(--space-small);
}

.ticket-meta {
  display: flex;
  align-items: center;
  gap: var(--space-small);
}

.ticket-id {
  font-size: var(--font-size-mini);
  font-weight: var(--font-weight-medium);
  color: var(--color-light-gray);
  font-family: var(--font-family-monospace);
}

.ticket-status {
  font-size: var(--font-size-mini);
  font-weight: var(--font-weight-medium);
  padding: var(--space-micro) var(--space-smaller);
  border-radius: var(--border-radius-small);
  text-transform: capitalize;

  &.status-open {
    background-color: var(--b-50);
    color: var(--b-700);
  }

  &.status-resolved {
    background-color: var(--g-50);
    color: var(--g-700);
  }

  &.status-pending {
    background-color: var(--y-50);
    color: var(--y-700);
  }

  &.status-snoozed {
    background-color: var(--s-50);
    color: var(--s-700);
  }
}

.similarity-score {
  flex-shrink: 0;
}

.score-circle {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  font-size: var(--font-size-mini);
  font-weight: var(--font-weight-bold);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);

  &.high {
    background-color: var(--g-100);
    color: var(--g-800);
  }

  &.medium {
    background-color: var(--y-100);
    color: var(--y-800);
  }

  &.low {
    background-color: var(--s-100);
    color: var(--s-800);
  }
}

.ticket-content {
  margin-bottom: var(--space-small);
}

.ticket-subject {
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-medium);
  color: var(--color-body);
  margin: 0 0 var(--space-micro);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.ticket-preview {
  font-size: var(--font-size-mini);
  color: var(--color-light-gray);
  margin: 0;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  line-height: 1.4;
}

.ticket-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-small);
}

.ticket-contact {
  display: flex;
  align-items: center;
  gap: var(--space-micro);
  color: var(--color-light-gray);
  font-size: var(--font-size-mini);
}

.contact-name {
  max-width: 150px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.ticket-date {
  font-size: var(--font-size-mini);
  color: var(--color-light-gray);
}

.ticket-arrow {
  position: absolute;
  right: var(--space-normal);
  top: 50%;
  transform: translateY(-50%);
  color: var(--color-light-gray);
  transition: all 0.2s ease;
}

.ticket-item:hover .ticket-arrow {
  color: var(--w-500);
  transform: translateY(-50%) translateX(4px);
}

/* Mobile responsive styles */
@media screen and (max-width: 768px) {
  .similar-tickets {
    padding: var(--space-small);
  }

  .ticket-item {
    padding: var(--space-small);
    padding-right: var(--space-large);
  }

  .ticket-header {
    flex-direction: column;
    align-items: flex-start;
    gap: var(--space-small);
  }

  .score-circle {
    width: 36px;
    height: 36px;
    font-size: 10px;
  }

  .contact-name {
    max-width: 100px;
  }
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  .similar-tickets {
    background-color: var(--color-background);
    border-color: var(--color-border);
  }

  .ticket-item {
    background-color: var(--color-background);
    border-color: var(--color-border);
  }
}
</style>
