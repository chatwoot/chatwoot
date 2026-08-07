<script setup>
import { computed, ref, watch, onMounted, useTemplateRef } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  useElementBounding,
  useResizeObserver,
  useTimeoutFn,
  useWindowSize,
} from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import { replaceVariablesInMessage } from '@chatwoot/utils';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useKeyboardNavigableList } from 'dashboard/composables/useKeyboardNavigableList';
import { stripUnsupportedFormatting } from 'dashboard/helper/editorHelper';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';
import PreviewPicker from 'dashboard/components-next/preview-picker/PreviewPicker.vue';

const props = defineProps({
  caretRect: {
    type: Object,
    default: null,
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

const emit = defineEmits(['replace', 'close']);

const MIN_HEIGHT = 280;
const MAX_HEIGHT = 360;
const MAX_WIDTH = 768;
const VIEWPORT_MARGIN = 16;
const GAP = 8;
const PREVIEW_MIN_WIDTH = 480;
// Characters kept before the match when a snippet has to skip ahead
const SNIPPET_LEAD = 24;
const SEARCH_DEBOUNCE = 200;
const HIGHLIGHT_CLASS = 'text-n-blue-text';

const store = useStore();
const { t } = useI18n();
const { getPlainText, formatMessage, highlightContent } = useMessageFormatter();

const cannedResponses = useMapGetter('getCannedResponses');
const anchorRef = useTemplateRef('anchorRef');
const pickerRef = useTemplateRef('pickerRef');
const selectedIndex = ref(0);
// The editor only holds the trigger character; the query is typed in the picker
const searchQuery = ref('');

const anchor = useElementBounding(anchorRef);
const { width: windowWidth, height: windowHeight } = useWindowSize();

const searchTerm = computed(() => searchQuery.value.trim());

const showPreview = computed(() => anchor.width.value >= PREVIEW_MIN_WIDTH);

const anchorStyle = computed(() => ({
  top: `${props.caretRect?.top ?? 0}px`,
  height: `${props.caretRect?.height ?? 0}px`,
}));

useResizeObserver(() => anchorRef.value?.parentElement, anchor.update);

// Placement is decided from the anchor alone. `useDropdownPosition` picks its side from
// the card's measured height, which here is derived from the side it picked — a loop that
// pins the card to whichever side it happened to fit on while the list was still empty.
const cardStyle = computed(() => {
  const above = anchor.top.value - VIEWPORT_MARGIN - GAP;
  const below =
    windowHeight.value - anchor.bottom.value - VIEWPORT_MARGIN - GAP;
  const placeAbove = above > below;

  const height = Math.min(MAX_HEIGHT, Math.max(placeAbove ? above : below, 0));
  const width = Math.min(anchor.width.value, MAX_WIDTH);
  const left = Math.min(
    anchor.left.value,
    windowWidth.value - width - VIEWPORT_MARGIN
  );

  return {
    left: `${Math.max(VIEWPORT_MARGIN, left)}px`,
    width: `${width}px`,
    maxHeight: `${height}px`,
    // A short list would otherwise leave the preview pane too shallow to read
    minHeight: showPreview.value ? `${Math.min(MIN_HEIGHT, height)}px` : null,
    ...(placeAbove
      ? { bottom: `${windowHeight.value - anchor.top.value + GAP}px` }
      : { top: `${anchor.bottom.value + GAP}px` }),
  };
});

// An empty term makes `highlightContent`'s regex match at every position, wrapping the
// whole string in empty spans
const highlightMatches = text =>
  searchTerm.value
    ? highlightContent(text, searchTerm.value, HIGHLIGHT_CLASS)
    : text;

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
    replaceVariablesInMessage({ message, variables: props.variables }),
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

const items = computed(() =>
  records.value.map(record => ({
    id: record.id,
    content: record.content,
    resolved: record.resolved,
    label: `/${record.shortCode}`,
    title: highlightMatches(`/${record.shortCode}`),
    subtitle: highlightMatches(buildSnippet(record.plainText)),
  }))
);

const selectedItem = computed(() => items.value[selectedIndex.value]);

const previewContent = computed(() =>
  formatMessage(selectedItem.value?.resolved || '')
);

const adjustScroll = () => pickerRef.value?.scrollSelectedIntoView();

const onSelect = () => {
  if (selectedItem.value) emit('replace', selectedItem.value.content);
};

const { moveSelectionUp, moveSelectionDown } = useKeyboardNavigableList({
  items,
  onSelect,
  adjustScroll,
  selectedIndex,
});

const withPicker = action => ({
  action: event => {
    event.preventDefault();
    action();
  },
  allowOnFocusedInput: true,
});

useKeyboardEvents({
  Tab: withPicker(moveSelectionDown),
  'Shift+Tab': withPicker(moveSelectionUp),
  Escape: withPicker(() => emit('close')),
});

const onListItemSelection = index => {
  selectedIndex.value = index;
  onSelect();
};

const { run: runFetch } = useAbortableRequest();

const fetchCannedResponses = () => {
  runFetch(signal =>
    store.dispatch('getCannedResponse', {
      searchKey: searchTerm.value,
      signal,
    })
  );
};

const { start: scheduleFetch } = useTimeoutFn(
  fetchCannedResponses,
  SEARCH_DEBOUNCE,
  { immediate: false }
);

watch(searchTerm, scheduleFetch);

watch(items, newItems => {
  if (selectedIndex.value > newItems.length - 1) {
    selectedIndex.value = 0;
    adjustScroll();
  }
});

onMounted(fetchCannedResponses);
</script>

<template>
  <div
    ref="anchorRef"
    class="absolute inset-x-0 pointer-events-none"
    :style="anchorStyle"
  />
  <TeleportWithDirection to="body">
    <PreviewPicker
      ref="pickerRef"
      v-model:selected-index="selectedIndex"
      v-model:search="searchQuery"
      v-on-click-outside="() => emit('close')"
      :items="items"
      :search-placeholder="t('COMBOBOX.SEARCH_PLACEHOLDER')"
      :empty-label="
        searchTerm
          ? t('COMBOBOX.EMPTY_SEARCH_RESULTS', { searchTerm })
          : t('COMBOBOX.EMPTY_STATE')
      "
      :preview-title="selectedItem?.label"
      :preview-content="previewContent"
      :show-preview="showPreview"
      data-popover-content
      class="fixed z-[9999]"
      :style="cardStyle"
      @select="onListItemSelection"
    />
  </TeleportWithDirection>
</template>
