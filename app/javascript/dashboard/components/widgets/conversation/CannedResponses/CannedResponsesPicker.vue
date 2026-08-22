<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { picoSearch } from '@chatwoot/pico-search';

const emit = defineEmits(['onSelect']);

const { t } = useI18n();
const store = useStore();
const { getPlainText } = useMessageFormatter();

const query = ref('');
const selectedCategory = ref(null);

const cannedResponses = useMapGetter('getCannedResponses');

onMounted(() => {
  store.dispatch('getCannedResponse', { usable: true });
});

const categories = computed(() => {
  const set = new Set();
  (cannedResponses.value || []).forEach(item => {
    if (item.category) set.add(item.category);
  });
  return [...set].sort((a, b) => a.localeCompare(b));
});

const categoryFiltered = computed(() => {
  const list = cannedResponses.value || [];
  if (selectedCategory.value === null) return list;
  if (selectedCategory.value === '') {
    return list.filter(item => !item.category);
  }
  return list.filter(item => item.category === selectedCategory.value);
});

const filteredResponses = computed(() => {
  const q = query.value.trim();
  if (!q) return categoryFiltered.value;
  return picoSearch(categoryFiltered.value, q, [
    { name: 'short_code', weight: 4 },
    { name: 'category', weight: 2 },
    'content',
  ]);
});

const chipClass = active =>
  active
    ? 'bg-n-brand text-white border-n-brand'
    : 'bg-n-alpha-black2 text-n-slate-12 border-n-weak hover:bg-n-alpha-2';

const previewContent = content => {
  const plain = getPlainText(content || '');
  return plain.length > 160 ? `${plain.slice(0, 160)}…` : plain;
};
</script>

<template>
  <div class="w-full">
    <div
      class="flex flex-1 gap-1 items-center px-2.5 py-0 mb-2.5 rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak hover:outline-n-slate-6 dark:hover:outline-n-slate-6 focus-within:outline-n-brand dark:focus-within:outline-n-brand"
    >
      <fluent-icon icon="search" class="text-n-slate-12" size="16" />
      <input
        v-model="query"
        type="search"
        :placeholder="t('CANNED_MGMT.PICKER.SEARCH_PLACEHOLDER')"
        class="reset-base w-full h-9 bg-transparent text-n-slate-12 !text-sm !outline-0"
      />
    </div>

    <div
      v-if="categories.length || (cannedResponses || []).some(r => !r.category)"
      class="flex flex-wrap gap-2 mb-2.5"
    >
      <button
        type="button"
        class="px-2.5 py-1 text-xs rounded-lg border border-solid transition-colors"
        :class="chipClass(selectedCategory === null)"
        @click="selectedCategory = null"
      >
        {{ t('CANNED_MGMT.PICKER.ALL_CATEGORIES') }}
      </button>
      <button
        v-for="cat in categories"
        :key="cat"
        type="button"
        class="px-2.5 py-1 text-xs rounded-lg border border-solid transition-colors"
        :class="chipClass(selectedCategory === cat)"
        @click="selectedCategory = cat"
      >
        {{ cat }}
      </button>
      <button
        v-if="(cannedResponses || []).some(r => !r.category)"
        type="button"
        class="px-2.5 py-1 text-xs rounded-lg border border-solid transition-colors"
        :class="chipClass(selectedCategory === '')"
        @click="selectedCategory = ''"
      >
        {{ t('CANNED_MGMT.PICKER.UNCATEGORIZED') }}
      </button>
    </div>

    <div
      class="bg-n-background outline-n-container outline outline-1 rounded-lg max-h-[18.75rem] overflow-y-auto p-2.5"
    >
      <div v-for="(item, i) in filteredResponses" :key="item.id || item.short_code">
        <button
          type="button"
          class="block p-2.5 w-full text-left rounded-lg cursor-pointer hover:bg-n-alpha-2 dark:hover:bg-n-solid-2"
          @click="emit('onSelect', item)"
        >
          <div class="flex justify-between items-center gap-2 mb-1.5">
            <p class="mb-0 text-sm font-medium text-n-slate-12">
              /{{ item.short_code }}
            </p>
            <div class="flex flex-shrink-0 gap-1 items-center">
              <span
                v-if="item.category"
                class="inline-block px-2 py-1 text-xs leading-none rounded-lg bg-n-slate-3 text-n-slate-12"
              >
                {{ item.category }}
              </span>
              <span
                class="inline-block px-2 py-1 text-xs leading-none rounded-lg bg-n-alpha-black2 text-n-slate-11"
              >
                {{
                  item.visibility === 'personal'
                    ? t('CANNED_MGMT.PICKER.PERSONAL_BADGE')
                    : t('CANNED_MGMT.PICKER.ACCOUNT_BADGE')
                }}
              </span>
            </div>
          </div>
          <p class="mb-0 text-sm text-n-slate-11 line-clamp-3">
            {{ previewContent(item.content) }}
          </p>
        </button>
        <hr
          v-if="i !== filteredResponses.length - 1"
          :key="`hr-${i}`"
          class="border-b border-solid border-n-weak my-2.5 mx-auto max-w-[95%]"
        />
      </div>
      <div v-if="!filteredResponses.length" class="py-8 text-center">
        <div v-if="query && (cannedResponses || []).length">
          <p class="mb-0 text-n-slate-11">
            {{ t('CANNED_MGMT.PICKER.NO_RESULTS') }}
            <strong>{{ query }}</strong>
          </p>
        </div>
        <p v-else class="mb-0 text-n-slate-11">
          {{ t('CANNED_MGMT.PICKER.EMPTY_PENDING_HINT') }}
        </p>
      </div>
    </div>
  </div>
</template>
