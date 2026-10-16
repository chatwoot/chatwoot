<script setup>
import { computed, onBeforeUnmount, ref, toRef, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useTrack } from 'dashboard/composables';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { CommandBar, createFrecency, useCommandBar } from '@bysivin/jumpbar';
import ConversationResolveAttributesModal from 'dashboard/components-next/ConversationWorkflow/ConversationResolveAttributesModal.vue';
import wootConstants from 'dashboard/constants/globals';
import { GENERAL_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import {
  isAConversationRoute,
  isAInboxViewRoute,
} from 'dashboard/helper/routeHelpers';
import { useGoToCommands } from 'dashboard/composables/commands/useGoToCommands';
import { useAppearanceCommands } from 'dashboard/composables/commands/useAppearanceCommands';
import { useInboxCommands } from 'dashboard/composables/commands/useInboxCommands';
import { useBulkActionCommands } from 'dashboard/composables/commands/useBulkActionCommands';
import { useConversationCommands } from 'dashboard/composables/commands/useConversationCommands';
import { useMacroCommands } from 'dashboard/composables/commands/useMacroCommands';
import { useCannedResponseCommands } from 'dashboard/composables/commands/useCannedResponseCommands';
import { useAccountCommands } from 'dashboard/composables/commands/useAccountCommands';
import { useHelpCommands } from 'dashboard/composables/commands/useHelpCommands';
import { useSnoozeSuggestions } from 'dashboard/composables/commands/useSnoozeSuggestions';
import { useSearchCommands } from 'dashboard/composables/commands/useSearchCommands';
import { useBackCommands } from 'dashboard/composables/commands/useBackCommands';

const props = defineProps({
  isPaywalled: { type: Boolean, default: false },
});

const PREFIXES = ['@', '#', '/', '?'];
const PATH_SCOPES = { reports: '/reports', settings: '/settings' };
const atRoot = ({ page }) => !page;

const store = useStore();
const route = useRoute();
const { t } = useI18n();
const bar = useCommandBar();

const currentChat = useMapGetter('getSelectedChat');
const selectedConversationIds = useMapGetter(
  'bulkActions/getSelectedConversationIds'
);
const accountId = useMapGetter('getCurrentAccountId');
const isRTL = useMapGetter('accounts/isRTL');

const { goToCommands } = useGoToCommands(toRef(props, 'isPaywalled'));
const { appearanceCommands } = useAppearanceCommands();
const { inboxCommands } = useInboxCommands();
const { bulkActionCommands } = useBulkActionCommands();
const { conversationCommands } = useConversationCommands();
const { cannedResponseCommands } = useCannedResponseCommands();
const { accountCommands } = useAccountCommands();
const { helpCommands } = useHelpCommands();
const { backCommands } = useBackCommands();
const { searchSnoozeSuggestions, snoozeCommands } = useSnoozeSuggestions();
const {
  searchLoadedConversations,
  searchConversations,
  searchContacts,
  searchArticles,
  searchEverything,
} = useSearchCommands();
const {
  macroCommands,
  pendingAttributes,
  submitPendingAttributes,
  dismissPendingAttributes,
} = useMacroCommands();

const resolveAttributesModalRef = ref(null);

const scopes = computed(() => {
  const list = ['page'];
  if (isAConversationRoute(route.name) || isAInboxViewRoute(route.name)) {
    list.push('conversation');
  }
  if (isAInboxViewRoute(route.name)) list.push('inbox_view');
  if (selectedConversationIds.value.length) list.push('bulk');
  Object.entries(PATH_SCOPES).forEach(([scope, path]) => {
    if (route.path?.includes(path)) list.push(scope);
  });
  return list;
});

const scopeLabel = computed(() => {
  const count = selectedConversationIds.value.length;
  if (count) return t('COMMAND_BAR.SELECTED_COUNT', { count });
  if (scopes.value.includes('conversation')) {
    return currentChat.value?.meta?.sender?.name ?? '';
  }
  return '';
});

const hints = computed(() => [
  { keys: ['↑', '↓'], label: t('COMMAND_BAR.HINTS.NAVIGATE') },
  { keys: ['↵'], label: t('COMMAND_BAR.HINTS.SELECT') },
  bar.page.value
    ? { keys: ['⌫'], label: t('COMMAND_BAR.HINTS.BACK') }
    : { keys: ['esc'], label: t('COMMAND_BAR.HINTS.CLOSE') },
]);

const sources = computed(() => {
  const general = [
    { id: 'goto', commands: () => goToCommands.value },
    { id: 'appearance', commands: () => appearanceCommands.value },
  ];
  if (props.isPaywalled) return general;

  return [
    { id: 'conversation', commands: () => conversationCommands.value },
    { id: 'snooze', commands: snoozeCommands },
    { id: 'bulk', commands: () => bulkActionCommands.value },
    { id: 'inbox', commands: () => inboxCommands.value },
    { id: 'macros', commands: () => macroCommands.value },
    { id: 'canned', commands: () => cannedResponseCommands.value },
    ...general,
    { id: 'account', commands: () => accountCommands.value },
    { id: 'help', commands: () => helpCommands.value },
    { id: 'snooze_suggestions', search: searchSnoozeSuggestions },
    ...[
      {
        id: 'loaded_conversations',
        minQuery: 1,
        search: searchLoadedConversations,
      },
      {
        id: 'conversations',
        minQuery: 3,
        debounce: 300,
        search: searchConversations,
      },
      { id: 'contacts', minQuery: 3, debounce: 300, search: searchContacts },
      { id: 'articles', minQuery: 3, debounce: 300, search: searchArticles },
      { id: 'everything', minQuery: 3, search: searchEverything },
    ].map(source => ({ ...source, when: atRoot })),
  ];
});

let keepContextMenuChat = false;

bar.configure({
  prefixes: PREFIXES,
  context: () => ({ scopes: scopes.value }),
  onSelect: item => {
    keepContextMenuChat = item.id.endsWith(
      wootConstants.SNOOZE_OPTIONS.UNTIL_CUSTOM_TIME
    );
    useTrack(GENERAL_EVENTS.COMMAND_BAR, {
      section: item.section,
      action: item.title,
    });
  },
  onClose: () => {
    if (!keepContextMenuChat) store.dispatch('setContextMenuChatId', null);
    keepContextMenuChat = false;
  },
});

watch(
  () => accountId.value,
  id => {
    bar.configure({
      frecency: createFrecency({
        key: `command_bar_usage_${id}`,
        storage: localStorage,
      }),
    });
  },
  { immediate: true }
);

let unregister = [];
watch(
  sources,
  list => {
    unregister.forEach(remove => remove());
    unregister = list.map(bar.register);
  },
  { immediate: true }
);

// Registered after the page sources so "Back to" lands below their actions.
let unregisterBack = () => {};
watch(
  () => route.fullPath,
  () => {
    unregisterBack();
    unregisterBack = bar.register({
      id: 'back',
      commands: () => backCommands.value,
    });
  },
  { immediate: true, flush: 'post' }
);

onBeforeUnmount(() => {
  unregister.forEach(remove => remove());
  unregisterBack();
});

watch(pendingAttributes, pending => {
  if (pending) {
    resolveAttributesModalRef.value?.open(
      pending.missing,
      pending.customAttributes
    );
  }
});

useKeyboardEvents({
  '$mod+KeyK': {
    action: event => {
      event.preventDefault();
      bar.toggle();
    },
    allowOnFocusedInput: true,
  },
});
</script>

<template>
  <CommandBar
    :placeholder="t('COMMAND_BAR.SEARCH_PLACEHOLDER')"
    :empty-text="t('COMMAND_BAR.EMPTY', { query: bar.query.value })"
    :scope-label="scopeLabel"
    :hints="hints"
    :dir="isRTL ? 'rtl' : 'ltr'"
  />
  <ConversationResolveAttributesModal
    ref="resolveAttributesModalRef"
    @submit="submitPendingAttributes"
    @close="dismissPendingAttributes"
  />
</template>
