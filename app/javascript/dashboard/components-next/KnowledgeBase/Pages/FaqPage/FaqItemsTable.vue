<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  items: {
    type: Array,
    default: () => [],
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  searchQuery: {
    type: String,
    default: '',
  },
  selectedItems: {
    type: Array,
    default: () => [],
  },
  meta: {
    type: Object,
    default: () => ({}),
  },
  currentPage: {
    type: Number,
    default: 1,
  },
});

const emit = defineEmits([
  'search',
  'page-change',
  'edit',
  'delete',
  'toggle-visibility',
  'bulk-delete',
  'update:selected-items',
]);

const { t } = useI18n();
const localSearch = ref(props.searchQuery);

const allSelected = computed(() =>
  props.items.length > 0 &&
  props.items.every(item => props.selectedItems.includes(item.id))
);

const hasSelection = computed(() => props.selectedItems.length > 0);

const onSearchInput = (e) => {
  localSearch.value = e.target.value;
  emit('search', localSearch.value);
};

const onToggleAll = () => {
  if (allSelected.value) {
    emit('update:selected-items', []);
  } else {
    emit('update:selected-items', props.items.map(item => item.id));
  }
};

const onToggleItem = (itemId) => {
  if (props.selectedItems.includes(itemId)) {
    emit('update:selected-items', props.selectedItems.filter(id => id !== itemId));
  } else {
    emit('update:selected-items', [...props.selectedItems, itemId]);
  }
};

const onEdit = (item) => {
  emit('edit', item);
};

const onDelete = (item) => {
  emit('delete', item);
};

const onToggleVisibility = (item) => {
  emit('toggle-visibility', item);
};

const onBulkDelete = () => {
  emit('bulk-delete');
};

const onPageChange = (page) => {
  emit('page-change', page);
};

const truncateText = (text, maxLength = 100) => {
  if (!text) return '';
  return text.length > maxLength ? `${text.substring(0, maxLength)}...` : text;
};

const stripHtml = (html) => {
  if (!html) return '';
  const doc = new DOMParser().parseFromString(html, 'text/html');
  return doc.body.textContent || '';
};
</script>

<template>
  <div class="flex flex-col h-full">
    <!-- Header -->
    <div class="flex items-center justify-between p-4 border-b border-n-weak">
      <!-- Search -->
      <div class="relative w-72">
        <span class="absolute left-3 top-1/2 -translate-y-1/2 i-lucide-search size-4 text-n-slate-10" />
        <input
          type="text"
          :value="localSearch"
          :placeholder="t('KNOWLEDGE_BASE.FAQ.SEARCH_PLACEHOLDER')"
          class="w-full pl-10 pr-4 py-2 text-sm rounded-lg border border-n-weak bg-n-alpha-1 focus:outline-none focus:ring-2 focus:ring-n-brand"
          @input="onSearchInput"
        />
      </div>

      <!-- Bulk Actions -->
      <div v-if="hasSelection" class="flex items-center gap-2">
        <span class="text-sm text-n-slate-11">
          {{ t('KNOWLEDGE_BASE.FAQ.ITEMS.SELECTED', { count: selectedItems.length }) }}
        </span>
        <woot-button
          color-scheme="alert"
          size="small"
          icon="delete"
          @click="onBulkDelete"
        >
          {{ t('KNOWLEDGE_BASE.FAQ.ITEMS.BULK_DELETE') }}
        </woot-button>
      </div>
    </div>

    <!-- Table -->
    <div class="flex-1 overflow-auto">
      <!-- Loading State -->
      <div v-if="isLoading" class="p-4 space-y-4">
        <div
          v-for="i in 5"
          :key="i"
          class="h-16 bg-n-alpha-2 rounded-lg animate-pulse"
        />
      </div>

      <!-- Empty State -->
      <div
        v-else-if="items.length === 0"
        class="flex flex-col items-center justify-center h-full text-n-slate-10"
      >
        <span class="i-lucide-help-circle size-12 mb-4" />
        <p class="text-sm">{{ t('KNOWLEDGE_BASE.FAQ.ITEMS.EMPTY') }}</p>
      </div>

      <!-- Items List -->
      <table v-else class="w-full">
        <thead class="bg-n-alpha-1 sticky top-0">
          <tr>
            <th class="w-12 p-4">
              <input
                type="checkbox"
                :checked="allSelected"
                class="rounded border-n-weak"
                @change="onToggleAll"
              />
            </th>
            <th class="text-left p-4 text-sm font-medium text-n-slate-11">
              {{ t('KNOWLEDGE_BASE.FAQ.ITEMS.QUESTION') }}
            </th>
            <th class="text-left p-4 text-sm font-medium text-n-slate-11 w-48">
              {{ t('KNOWLEDGE_BASE.FAQ.ITEMS.CATEGORY') }}
            </th>
            <th class="text-left p-4 text-sm font-medium text-n-slate-11 w-32">
              {{ t('KNOWLEDGE_BASE.FAQ.ITEMS.LANGUAGES') }}
            </th>
            <th class="text-left p-4 text-sm font-medium text-n-slate-11 w-24">
              {{ t('KNOWLEDGE_BASE.FAQ.ITEMS.STATUS') }}
            </th>
            <th class="w-32 p-4" />
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="item in items"
            :key="item.id"
            class="border-b border-n-weak hover:bg-n-alpha-1 transition-colors"
          >
            <td class="p-4">
              <input
                type="checkbox"
                :checked="selectedItems.includes(item.id)"
                class="rounded border-n-weak"
                @change="onToggleItem(item.id)"
              />
            </td>
            <td class="p-4">
              <div class="space-y-1">
                <p class="text-sm font-medium text-n-slate-12">
                  {{ truncateText(item.primary_question, 80) }}
                </p>
                <p class="text-xs text-n-slate-10">
                  {{ truncateText(stripHtml(item.primary_answer), 120) }}
                </p>
              </div>
            </td>
            <td class="p-4">
              <span
                v-if="item.category"
                class="inline-flex items-center gap-1 px-2 py-1 text-xs rounded-full bg-n-alpha-2"
              >
                <span class="i-lucide-folder size-3" />
                {{ item.category.name }}
              </span>
              <span v-else class="text-xs text-n-slate-10">—</span>
            </td>
            <td class="p-4">
              <div class="flex gap-1">
                <span
                  v-for="lang in item.available_languages"
                  :key="lang"
                  class="px-1.5 py-0.5 text-xs rounded bg-n-alpha-2 uppercase"
                >
                  {{ lang }}
                </span>
              </div>
            </td>
            <td class="p-4">
              <span
                class="inline-flex items-center gap-1 px-2 py-1 text-xs rounded-full"
                :class="[
                  item.is_visible
                    ? 'bg-n-jade-3 text-n-jade-11'
                    : 'bg-n-slate-3 text-n-slate-11'
                ]"
              >
                <span
                  class="size-2 rounded-full"
                  :class="[item.is_visible ? 'bg-n-jade-9' : 'bg-n-slate-9']"
                />
                {{ item.is_visible ? t('KNOWLEDGE_BASE.FAQ.ITEMS.VISIBLE') : t('KNOWLEDGE_BASE.FAQ.ITEMS.HIDDEN') }}
              </span>
            </td>
            <td class="p-4">
              <div class="flex items-center justify-end gap-1">
                <button
                  class="p-2 rounded-lg hover:bg-n-alpha-2 text-n-slate-11"
                  :title="item.is_visible ? t('KNOWLEDGE_BASE.FAQ.ITEMS.HIDE') : t('KNOWLEDGE_BASE.FAQ.ITEMS.SHOW')"
                  @click="onToggleVisibility(item)"
                >
                  <span
                    class="size-4"
                    :class="[item.is_visible ? 'i-lucide-eye-off' : 'i-lucide-eye']"
                  />
                </button>
                <button
                  class="p-2 rounded-lg hover:bg-n-alpha-2 text-n-slate-11"
                  :title="t('KNOWLEDGE_BASE.FAQ.ITEMS.EDIT')"
                  @click="onEdit(item)"
                >
                  <span class="i-lucide-pencil size-4" />
                </button>
                <button
                  class="p-2 rounded-lg hover:bg-n-alpha-2 text-n-ruby-11"
                  :title="t('KNOWLEDGE_BASE.FAQ.ITEMS.DELETE')"
                  @click="onDelete(item)"
                >
                  <span class="i-lucide-trash-2 size-4" />
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Pagination -->
    <div
      v-if="meta.total_pages > 1"
      class="flex items-center justify-between p-4 border-t border-n-weak"
    >
      <span class="text-sm text-n-slate-11">
        {{ t('KNOWLEDGE_BASE.FAQ.PAGINATION.SHOWING', {
          from: (currentPage - 1) * 50 + 1,
          to: Math.min(currentPage * 50, meta.total_count),
          total: meta.total_count
        }) }}
      </span>
      <div class="flex items-center gap-1">
        <button
          class="px-3 py-1 text-sm rounded-lg hover:bg-n-alpha-2 disabled:opacity-50"
          :disabled="currentPage === 1"
          @click="onPageChange(currentPage - 1)"
        >
          {{ t('KNOWLEDGE_BASE.FAQ.PAGINATION.PREV') }}
        </button>
        <button
          class="px-3 py-1 text-sm rounded-lg hover:bg-n-alpha-2 disabled:opacity-50"
          :disabled="currentPage === meta.total_pages"
          @click="onPageChange(currentPage + 1)"
        >
          {{ t('KNOWLEDGE_BASE.FAQ.PAGINATION.NEXT') }}
        </button>
      </div>
    </div>
  </div>
</template>
