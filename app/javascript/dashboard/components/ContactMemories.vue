<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Label from 'dashboard/components/ui/Label.vue';

const props = defineProps({
  contactId: {
    type: [Number, String],
    required: true,
  },
});

const emit = defineEmits(['memory-added', 'memory-updated']);

const { t } = useI18n();
const store = useStore();

const memories = ref([]);
const loading = ref(false);
const searchQuery = ref('');
const showAddForm = ref(false);
const newMemory = ref({
  content: '',
  importance: 'medium',
  tags: [],
});

const accountId = useMapGetter('getCurrentAccountId');

const importanceOptions = [
  { value: 'low', label: 'Low', color: 'var(--color-light-gray)' },
  { value: 'medium', label: 'Medium', color: 'var(--w-500)' },
  { value: 'high', label: 'High', color: 'var(--r-500)' },
];

const loadMemories = async () => {
  if (!props.contactId) return;

  loading.value = true;

  try {
    const response = await store.dispatch('contactMemories/fetch', {
      accountId: accountId.value,
      contactId: props.contactId,
    });

    memories.value = response.data || [];
  } catch (err) {
    console.error('Failed to load contact memories:', err);
    useAlert(t('CONTACT_MEMORIES.ERROR.LOAD'));
    memories.value = [];
  } finally {
    loading.value = false;
  }
};

const addMemory = async () => {
  if (!newMemory.value.content.trim()) {
    useAlert(t('CONTACT_MEMORIES.ERROR.EMPTY_CONTENT'));
    return;
  }

  try {
    const response = await store.dispatch('contactMemories/create', {
      accountId: accountId.value,
      contactId: props.contactId,
      memory: newMemory.value,
    });

    memories.value.unshift(response.data);
    newMemory.value = { content: '', importance: 'medium', tags: [] };
    showAddForm.value = false;
    useAlert(t('CONTACT_MEMORIES.SUCCESS.ADDED'));
    emit('memory-added', response.data);
  } catch (err) {
    console.error('Failed to add memory:', err);
    useAlert(t('CONTACT_MEMORIES.ERROR.ADD'));
  }
};

const searchMemories = async () => {
  if (!searchQuery.value.trim()) {
    loadMemories();
    return;
  }

  loading.value = true;

  try {
    const response = await store.dispatch('contactMemories/search', {
      accountId: accountId.value,
      contactId: props.contactId,
      query: searchQuery.value,
    });

    memories.value = response.data || [];
  } catch (err) {
    console.error('Failed to search memories:', err);
    useAlert(t('CONTACT_MEMORIES.ERROR.SEARCH'));
  } finally {
    loading.value = false;
  }
};

const getImportanceColor = (importance) => {
  const option = importanceOptions.find(opt => opt.value === importance);
  return option ? option.color : 'var(--color-light-gray)';
};

const filteredMemories = computed(() => {
  if (!searchQuery.value) return memories.value;
  
  const query = searchQuery.value.toLowerCase();
  return memories.value.filter(memory =>
    memory.content.toLowerCase().includes(query) ||
    (memory.tags && memory.tags.some(tag => tag.toLowerCase().includes(query)))
  );
});

const hasMemories = computed(() => memories.value.length > 0);

watch(() => props.contactId, () => {
  loadMemories();
}, { immediate: true });
</script>

<template>
  <div class="contact-memories">
    <div class="memories-header">
      <div class="header-content">
        <h4 class="header-title">
          <fluent-icon icon="notebook" size="16" />
          {{ t('CONTACT_MEMORIES.TITLE') }}
        </h4>
        <Label
          title="Powered by ZeroDB AI"
          color-scheme="primary"
          variant="smooth"
          small
          icon="sparkle"
        />
      </div>
      
      <button
        class="add-button"
        :aria-label="t('CONTACT_MEMORIES.ADD')"
        @click="showAddForm = !showAddForm"
      >
        <fluent-icon :icon="showAddForm ? 'dismiss' : 'add'" size="16" />
      </button>
    </div>

    <div v-if="showAddForm" class="add-memory-form">
      <div class="form-group">
        <textarea
          v-model="newMemory.content"
          class="memory-input"
          :placeholder="t('CONTACT_MEMORIES.PLACEHOLDER')"
          rows="3"
          :aria-label="t('CONTACT_MEMORIES.INPUT_LABEL')"
        />
      </div>

      <div class="form-row">
        <div class="importance-selector">
          <label class="field-label">{{ t('CONTACT_MEMORIES.IMPORTANCE') }}</label>
          <div class="importance-options">
            <button
              v-for="option in importanceOptions"
              :key="option.value"
              class="importance-option"
              :class="{ active: newMemory.importance === option.value }"
              :aria-label="`Set importance to ${option.label}`"
              @click="newMemory.importance = option.value"
            >
              <span
                class="importance-indicator"
                :style="{ backgroundColor: option.color }"
              />
              {{ option.label }}
            </button>
          </div>
        </div>
      </div>

      <div class="form-actions">
        <button class="cancel-button" @click="showAddForm = false">
          {{ t('CONTACT_MEMORIES.CANCEL') }}
        </button>
        <button class="save-button" @click="addMemory">
          {{ t('CONTACT_MEMORIES.SAVE') }}
        </button>
      </div>
    </div>

    <div class="search-container">
      <div class="search-input-wrapper">
        <fluent-icon icon="search" size="16" class="search-icon" />
        <input
          v-model="searchQuery"
          type="text"
          class="search-input"
          :placeholder="t('CONTACT_MEMORIES.SEARCH_PLACEHOLDER')"
          :aria-label="t('CONTACT_MEMORIES.SEARCH_LABEL')"
          @input="searchMemories"
        />
        <button
          v-if="searchQuery"
          class="clear-search"
          :aria-label="t('CONTACT_MEMORIES.CLEAR_SEARCH')"
          @click="searchQuery = ''; loadMemories();"
        >
          <fluent-icon icon="dismiss" size="14" />
        </button>
      </div>
    </div>

    <div v-if="loading" class="loading-container">
      <Spinner size="small" />
      <p class="loading-text">{{ t('CONTACT_MEMORIES.LOADING') }}</p>
    </div>

    <div v-else-if="!hasMemories" class="empty-state">
      <fluent-icon icon="notebook" size="32" class="empty-icon" />
      <p class="empty-message">{{ t('CONTACT_MEMORIES.EMPTY_STATE') }}</p>
      <p class="empty-hint">{{ t('CONTACT_MEMORIES.EMPTY_HINT') }}</p>
    </div>

    <div v-else class="memories-list" role="list">
      <div
        v-for="memory in filteredMemories"
        :key="memory.id"
        class="memory-item"
        role="listitem"
      >
        <div class="memory-header">
          <span
            class="importance-dot"
            :style="{ backgroundColor: getImportanceColor(memory.importance) }"
            :title="`Importance: ${memory.importance}`"
          />
          <time class="memory-date" :datetime="memory.created_at">
            {{ new Date(memory.created_at).toLocaleDateString() }}
          </time>
        </div>
        
        <p class="memory-content">{{ memory.content }}</p>
        
        <div v-if="memory.tags && memory.tags.length > 0" class="memory-tags">
          <span
            v-for="tag in memory.tags"
            :key="tag"
            class="memory-tag"
          >
            #{{ tag }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.contact-memories {
  display: flex;
  flex-direction: column;
  background-color: var(--white);
  border: 1px solid var(--color-border-light);
  border-radius: var(--border-radius-normal);
  padding: var(--space-normal);
  height: 100%;
}

.memories-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  margin-bottom: var(--space-normal);
  padding-bottom: var(--space-small);
  border-bottom: 1px solid var(--color-border-light);
}

.header-content {
  display: flex;
  flex-direction: column;
  gap: var(--space-small);
  flex: 1;
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

.add-button {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: var(--space-micro);
  background-color: var(--w-500);
  color: var(--white);
  border: none;
  border-radius: var(--border-radius-small);
  cursor: pointer;
  transition: all 0.2s ease;

  &:hover {
    background-color: var(--w-600);
  }

  &:focus {
    outline: 2px solid var(--w-500);
    outline-offset: 2px;
  }
}

.add-memory-form {
  background-color: var(--color-background-light);
  border: 1px solid var(--color-border-light);
  border-radius: var(--border-radius-normal);
  padding: var(--space-normal);
  margin-bottom: var(--space-normal);
  animation: slideDown 0.2s ease;
}

@keyframes slideDown {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.form-group {
  margin-bottom: var(--space-normal);
}

.memory-input {
  width: 100%;
  padding: var(--space-small);
  border: 1px solid var(--color-border);
  border-radius: var(--border-radius-normal);
  font-size: var(--font-size-small);
  font-family: inherit;
  resize: vertical;
  transition: border-color 0.2s ease;

  &:focus {
    outline: none;
    border-color: var(--w-500);
    box-shadow: 0 0 0 3px var(--w-100);
  }
}

.form-row {
  margin-bottom: var(--space-normal);
}

.field-label {
  display: block;
  font-size: var(--font-size-mini);
  font-weight: var(--font-weight-medium);
  color: var(--color-body);
  margin-bottom: var(--space-smaller);
}

.importance-options {
  display: flex;
  gap: var(--space-small);
}

.importance-option {
  display: flex;
  align-items: center;
  gap: var(--space-micro);
  padding: var(--space-smaller) var(--space-small);
  background-color: var(--white);
  border: 1px solid var(--color-border);
  border-radius: var(--border-radius-small);
  font-size: var(--font-size-mini);
  cursor: pointer;
  transition: all 0.2s ease;

  &:hover {
    border-color: var(--w-300);
  }

  &.active {
    border-color: var(--w-500);
    background-color: var(--w-50);
  }

  &:focus {
    outline: 2px solid var(--w-500);
    outline-offset: 2px;
  }
}

.importance-indicator {
  display: inline-block;
  width: 8px;
  height: 8px;
  border-radius: 50%;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-small);
}

.cancel-button,
.save-button {
  padding: var(--space-smaller) var(--space-normal);
  border: none;
  border-radius: var(--border-radius-normal);
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-medium);
  cursor: pointer;
  transition: all 0.2s ease;

  &:focus {
    outline: 2px solid var(--w-500);
    outline-offset: 2px;
  }
}

.cancel-button {
  background-color: var(--white);
  color: var(--color-body);
  border: 1px solid var(--color-border);

  &:hover {
    background-color: var(--color-background-light);
  }
}

.save-button {
  background-color: var(--w-500);
  color: var(--white);

  &:hover {
    background-color: var(--w-600);
  }
}

.search-container {
  margin-bottom: var(--space-normal);
}

.search-input-wrapper {
  position: relative;
  display: flex;
  align-items: center;
}

.search-icon {
  position: absolute;
  left: var(--space-small);
  color: var(--color-light-gray);
  pointer-events: none;
}

.search-input {
  width: 100%;
  padding: var(--space-smaller) var(--space-large) var(--space-smaller) var(--space-larger);
  border: 1px solid var(--color-border);
  border-radius: var(--border-radius-normal);
  font-size: var(--font-size-small);
  transition: border-color 0.2s ease;

  &:focus {
    outline: none;
    border-color: var(--w-500);
    box-shadow: 0 0 0 3px var(--w-100);
  }
}

.clear-search {
  position: absolute;
  right: var(--space-small);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: var(--space-micro);
  background: none;
  border: none;
  color: var(--color-light-gray);
  cursor: pointer;
  border-radius: var(--border-radius-small);

  &:hover {
    background-color: var(--color-background-light);
  }

  &:focus {
    outline: 2px solid var(--w-500);
    outline-offset: 2px;
  }
}

.loading-container,
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

.memories-list {
  flex: 1;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: var(--space-small);
}

.memory-item {
  background-color: var(--color-background-light);
  border: 1px solid var(--color-border-light);
  border-radius: var(--border-radius-normal);
  padding: var(--space-normal);
  transition: all 0.2s ease;

  &:hover {
    border-color: var(--w-300);
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
  }
}

.memory-header {
  display: flex;
  align-items: center;
  gap: var(--space-small);
  margin-bottom: var(--space-small);
}

.importance-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  flex-shrink: 0;
}

.memory-date {
  font-size: var(--font-size-mini);
  color: var(--color-light-gray);
}

.memory-content {
  font-size: var(--font-size-small);
  color: var(--color-body);
  line-height: 1.5;
  margin: 0 0 var(--space-small);
  white-space: pre-wrap;
  word-break: break-word;
}

.memory-tags {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-micro);
}

.memory-tag {
  font-size: var(--font-size-mini);
  color: var(--w-700);
  background-color: var(--w-50);
  padding: var(--space-micro) var(--space-smaller);
  border-radius: var(--border-radius-small);
}

/* Mobile responsive styles */
@media screen and (max-width: 768px) {
  .contact-memories {
    padding: var(--space-small);
  }

  .importance-options {
    flex-direction: column;
  }

  .importance-option {
    width: 100%;
  }
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  .contact-memories {
    background-color: var(--color-background);
    border-color: var(--color-border);
  }

  .memory-item {
    background-color: var(--color-background);
    border-color: var(--color-border);
  }

  .add-memory-form {
    background-color: var(--color-background);
  }

  .memory-input {
    background-color: var(--color-background);
    color: var(--white);
  }
}
</style>
