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

const store = useStore();
const { t } = useI18n();
const { getPlainText, formatMessage, normalizeForSearch, highlightContent } =
  useMessageFormatter();

const cannedResponses = useMapGetter('getCannedResponses');
const uiFlags = useMapGetter('getUIFlags');
// The trigger can already be followed by text, from a draft or a caret moved back onto it
const searchQuery = ref(props.searchKey);

const searchTerm = computed(() => searchQuery.value.trim());
const normalizedTerm = computed(() => normalizeForSearch(searchTerm.value));

const buildSnippet = text => {
  const normalizedText = normalizeForSearch(text);
  const index = normalizedText.indexOf(normalizedTerm.value);
  if (index <= SNIPPET_LEAD || normalizedText.length !== text.length) {
    return text;
  }

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

// Raw content, so the open conversation's contact never changes the results
const records = computed(() =>
  cannedResponses.value.map(({ id, short_code: shortCode, content }) => {
    const plainText = getPlainText(content)
      .normalize('NFC')
      .replace(/\s+/g, ' ')
      .trim();
    return {
      id,
      content,
      shortCode,
      plainText,
      searchShortCode: normalizeForSearch(shortCode),
      searchText: normalizeForSearch(plainText),
    };
  })
);

const filteredRecords = computed(() => {
  if (!normalizedTerm.value) return records.value;

  return picoSearch(records.value, normalizedTerm.value, [
    { name: 'searchShortCode', weight: 1 },
    'searchText',
  ]);
});

const items = computed(() =>
  filteredRecords.value.map(record => ({
    id: record.id,
    content: record.content,
    label: `/${record.shortCode}`,
    title: highlightContent(
      `/${record.shortCode}`,
      searchTerm.value,
      HIGHLIGHT_CLASS
    ),
    subtitle: highlightContent(
      buildSnippet(record.plainText),
      searchTerm.value,
      HIGHLIGHT_CLASS
    ),
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
        v-dompurify-html="
          formatMessage(item ? resolveContent(item.content) : '')
        "
        class="px-4 py-3 prose prose-bubble !max-w-none prose-a:text-n-brand"
      />
    </template>
  </CaretAnchoredPicker>
</template>
