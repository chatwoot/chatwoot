<script setup>
import { computed, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { picoSearch } from '@chatwoot/pico-search';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import {
  resolveVariablesInMessage,
  stripUnsupportedFormatting,
} from 'dashboard/helper/editorHelper';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { escapeHtml } from 'shared/helpers/HTMLSanitizer';
import CaretAnchoredPicker from 'dashboard/components-next/preview-picker/CaretAnchoredPicker.vue';

const props = defineProps({
  caretPosition: {
    type: Object,
    default: null,
  },
  searchKey: {
    type: String,
    default: '',
  },
  variables: {
    type: Object,
    default: () => ({}),
  },
  schema: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['replace', 'close', 'removeTrigger']);

// Characters kept before the match when a snippet has to skip ahead
const SNIPPET_LEAD = 24;
const HIGHLIGHT_CLASS = 'text-n-blue-text';
// Every rendered row is rebuilt and sanitized on each keystroke, so the list is capped
const MAX_ITEMS = 50;

const store = useStore();
const { t } = useI18n();
const { getPlainText, formatMessage } = useMessageFormatter();

const cannedResponses = useMapGetter('getCannedResponses');
const uiFlags = useMapGetter('getUIFlags');
// The trigger can already be followed by text, from a draft or a caret moved back onto it
const searchQuery = ref(props.searchKey);

const searchTerm = computed(() => searchQuery.value.trim());

// The text is already plain, so it is split on the term directly. `highlightContent`
// would render it through markdown and parse it back for every row on every keystroke.
// An empty term would match at every position, wrapping the string in empty spans.
const highlightMatches = text => {
  if (!searchTerm.value) return escapeHtml(text);

  const escapedTerm = searchTerm.value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return text
    .split(new RegExp(`(${escapedTerm})`, 'ig'))
    .map((part, index) =>
      index % 2
        ? `<span class="${HIGHLIGHT_CLASS}">${escapeHtml(part)}</span>`
        : escapeHtml(part)
    )
    .join('');
};

const buildSnippet = text => {
  const term = searchTerm.value;
  if (!term) return text;

  const index = text.toLowerCase().indexOf(term.toLowerCase());
  if (index <= SNIPPET_LEAD) return text;

  return `…${text.slice(index - SNIPPET_LEAD)}`;
};

// Both steps mirror what insertion does: variables are substituted, then formatting the
// channel's schema cannot carry is stripped. Previewing the raw content would advertise
// styling the message never ends up with.
const resolveContent = message =>
  stripUnsupportedFormatting(
    resolveVariablesInMessage(message, props.variables),
    props.schema
  );

const records = computed(() =>
  cannedResponses.value.map(({ id, short_code: shortCode, content }) => {
    const resolved = resolveContent(content);
    return {
      id,
      content,
      resolved,
      shortCode,
      plainText: getPlainText(resolved).replace(/\s+/g, ' ').trim(),
    };
  })
);

const filteredRecords = computed(() => {
  if (!searchTerm.value) return records.value;

  return picoSearch(records.value, searchTerm.value, [
    { name: 'shortCode', weight: 1 },
    'plainText',
  ]);
});

const items = computed(() =>
  filteredRecords.value.slice(0, MAX_ITEMS).map(record => ({
    id: record.id,
    content: record.content,
    resolved: record.resolved,
    label: `/${record.shortCode}`,
    title: highlightMatches(`/${record.shortCode}`),
    subtitle: highlightMatches(buildSnippet(record.plainText)),
  }))
);

const onSelect = item => emit('replace', item.content);

onMounted(() => store.dispatch('getCannedResponse'));
</script>

<template>
  <CaretAnchoredPicker
    v-model:search="searchQuery"
    :caret-position="caretPosition"
    :items="items"
    :search-placeholder="t('COMBOBOX.SEARCH_PLACEHOLDER')"
    :is-loading="uiFlags.fetchingList"
    :empty-label="
      searchTerm
        ? t('COMBOBOX.EMPTY_SEARCH_RESULTS', { searchTerm })
        : t('COMBOBOX.EMPTY_STATE')
    "
    @select="onSelect"
    @close="emit('close')"
    @remove-trigger="emit('removeTrigger')"
  >
    <template #preview="{ item }">
      <div
        v-dompurify-html="formatMessage(item?.resolved || '')"
        class="px-4 py-3 prose prose-bubble !max-w-none prose-a:text-n-brand"
      />
    </template>
  </CaretAnchoredPicker>
</template>
