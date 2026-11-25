<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import CreateChannelModal from './CreateChannelModal.vue';
import CreateDMModal from './CreateDMModal.vue';
import CreateCategoryModal from './CreateCategoryModal.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Draggable from 'vuedraggable';
import { emitter } from 'shared/helpers/mitt';
import {
  currentDateLocale,
  dateTimeFormat,
} from 'shared/helpers/localizedDate';
import ProFeatureNudge from './ProFeatureNudge.vue';
import {
  useBreakpoints,
  breakpointsTailwind,
  useEventListener,
} from '@vueuse/core';
import {
  useInternalChatSidebar,
  MIN_WIDTH,
  MAX_WIDTH,
} from 'dashboard/composables/useInternalChatSidebar';

const store = useStore();
const { t } = useI18n();
const route = useRoute();
const router = useRouter();

const currentRole = useMapGetter('getCurrentRole');
const isAdmin = computed(() => currentRole.value === 'administrator');
const isRTL = useMapGetter('accounts/isRTL');

const breakpoints = useBreakpoints(breakpointsTailwind);
const isSmallScreen = breakpoints.smaller('md');

const { sidebarWidth, setSidebarWidth, commitWidth, collapse } =
  useInternalChatSidebar();

// Arrow keys on the focused handle, so resizing isn't pointer-only.
const KEYBOARD_STEP = 16;

const nudgeWidth = delta => {
  setSidebarWidth(sidebarWidth.value + (isRTL.value ? -delta : delta));
  commitWidth();
};

// Resize handle, mirroring components-next/sidebar/Sidebar.vue
const isResizing = ref(false);
const startX = ref(0);
const startWidth = ref(0);

const getClientX = event =>
  event.touches ? event.touches[0].clientX : event.clientX;

const onResizeStart = event => {
  isResizing.value = true;
  startX.value = getClientX(event);
  startWidth.value = sidebarWidth.value;
  Object.assign(document.body.style, {
    cursor: 'col-resize',
    userSelect: 'none',
  });
  event.preventDefault();
};

const onResizeMove = event => {
  if (!isResizing.value) return;
  const delta = isRTL.value
    ? startX.value - getClientX(event)
    : getClientX(event) - startX.value;
  setSidebarWidth(startWidth.value + delta);
};

const onResizeEnd = () => {
  if (!isResizing.value) return;
  isResizing.value = false;
  Object.assign(document.body.style, { cursor: '', userSelect: '' });
  commitWidth();
};

useEventListener(document, 'mousemove', onResizeMove);
useEventListener(document, 'mouseup', onResizeEnd);
useEventListener(document, 'touchmove', onResizeMove, { passive: false });
useEventListener(document, 'touchend', onResizeEnd);

const searchQuery = ref('');
let searchDebounceTimer = null;
const isSearchPending = ref(false);
const createChannelModalRef = ref(null);
const createDMModalRef = ref(null);
const createCategoryModalRef = ref(null);

// Search store
const searchChannels = computed(
  () => store.getters['internalChat/search/getChannels']
);
const searchDMs = computed(() => store.getters['internalChat/search/getDMs']);
const searchMessages = computed(
  () => store.getters['internalChat/search/getMessages']
);
const searchUIFlags = computed(
  () => store.getters['internalChat/search/getUIFlags']
);
const isSearchLimited = computed(
  () => store.getters['internalChat/search/isSearchLimited']
);

const accountId = computed(() => {
  return route.params.accountId;
});

const showArchived = ref(false);
const archivedChannels = computed(
  () => store.getters['internalChat/getArchivedChannels']
);

function toggleArchivedSection() {
  showArchived.value = !showArchived.value;
  if (showArchived.value) {
    store.dispatch('internalChat/fetchArchived');
  }
}

const isSearchMode = computed(() => searchQuery.value.trim().length >= 1);
const isSearchReady = computed(() => searchQuery.value.trim().length >= 3);

const hasSearchResults = computed(
  () =>
    searchChannels.value.length > 0 ||
    searchDMs.value.length > 0 ||
    searchMessages.value.length > 0
);

watch(searchQuery, newVal => {
  clearTimeout(searchDebounceTimer);
  const trimmed = newVal.trim();
  if (trimmed.length < 3) {
    isSearchPending.value = false;
    store.dispatch('internalChat/search/clearSearch');
    return;
  }
  isSearchPending.value = true;
  searchDebounceTimer = setTimeout(() => {
    isSearchPending.value = false;
    store.dispatch('internalChat/search/search', {
      query: trimmed,
      page: 1,
    });
  }, 300);
});

function clearSearch() {
  searchQuery.value = '';
  store.dispatch('internalChat/search/clearSearch');
}

function loadMoreMessages() {
  const nextPage = searchUIFlags.value.currentPage + 1;
  store.dispatch('internalChat/search/search', {
    query: searchQuery.value.trim(),
    page: nextPage,
  });
}

function navigateToMessage(message) {
  const routeName =
    message.channel_type === 'dm'
      ? 'internal_chat_dm'
      : 'internal_chat_channel';
  const query = { messageId: message.id };
  if (message.parent_id) query.parentId = message.parent_id;
  router.push({
    name: routeName,
    params: { accountId: accountId.value, channelId: message.channel_id },
    query,
  });
  emitter.emit('internal-chat:jump-to-message', {
    channelId: message.channel_id,
    messageId: message.id,
    parentId: message.parent_id || null,
  });
}

function stripMarkup(text) {
  if (!text) return '';
  // Convert mention links [@Name](mention://...) to just @Name
  let clean = text.replace(/\[@([^\]]*)\]\(mention:\/\/[^)]*\)/g, '@$1');
  // Strip remaining markdown links [text](url) to just text
  clean = clean.replace(/\[([^\]]*)\]\([^)]*\)/g, '$1');
  // Strip any remaining HTML tags
  clean = clean.replace(/<[^>]+>/g, '');
  return clean;
}

function normalizeText(value) {
  return (value || '')
    .normalize('NFD')
    .replace(/\p{Diacritic}/gu, '')
    .toLowerCase();
}

function truncateAroundMatch(text, query, maxLen = 120) {
  if (!text) return '';
  const idx = normalizeText(text).indexOf(normalizeText(query));
  if (idx === -1 || text.length <= maxLen) return text;
  const start = Math.max(0, idx - Math.floor(maxLen / 2));
  const end = Math.min(text.length, start + maxLen);
  let snippet = text.slice(start, end);
  if (start > 0) snippet = `...${snippet}`;
  if (end < text.length) snippet = `${snippet}...`;
  return snippet;
}

function escapeHtml(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function highlightMatch(text, query) {
  if (!query || !text) return escapeHtml(text || '');
  const clean = stripMarkup(text);
  const snippet = truncateAroundMatch(clean, query);
  const normSnippet = normalizeText(snippet);
  const normQuery = normalizeText(query);
  if (!normQuery) return escapeHtml(snippet);

  const parts = [];
  let start = 0;
  let idx = normSnippet.indexOf(normQuery);
  while (idx !== -1) {
    if (idx > start) parts.push(escapeHtml(snippet.slice(start, idx)));
    const matchEnd = idx + normQuery.length;
    parts.push(`<mark>${escapeHtml(snippet.slice(idx, matchEnd))}</mark>`);
    start = matchEnd;
    idx = normSnippet.indexOf(normQuery, start);
  }
  if (start < snippet.length) parts.push(escapeHtml(snippet.slice(start)));
  return parts.join('');
}

function formatMessageTime(createdAt) {
  const date =
    typeof createdAt === 'number'
      ? new Date(createdAt * 1000)
      : new Date(createdAt);
  const now = new Date();
  if (date.toDateString() === now.toDateString()) {
    return dateTimeFormat(currentDateLocale(), {
      hour: '2-digit',
      minute: '2-digit',
    }).format(date);
  }
  return dateTimeFormat(currentDateLocale(), {
    month: 'short',
    day: 'numeric',
  }).format(date);
}

const collapsedSections = ref(
  new Set(
    JSON.parse(localStorage.getItem('internal_chat_collapsed_sections') || '[]')
  )
);

function toggleSection(key) {
  if (collapsedSections.value.has(key)) {
    collapsedSections.value.delete(key);
  } else {
    collapsedSections.value.add(key);
  }
  // Trigger reactivity
  collapsedSections.value = new Set(collapsedSections.value);
  localStorage.setItem(
    'internal_chat_collapsed_sections',
    JSON.stringify([...collapsedSections.value])
  );
}

function isSectionCollapsed(key) {
  return collapsedSections.value.has(key);
}

const uiFlags = computed(() => store.getters['internalChat/getUIFlags']);

const channels = computed(() => {
  return store.getters['internalChat/getChannels'] || [];
});

const categories = computed(() => {
  return store.getters['internalChat/getCategories'] || [];
});

const favoriteChannels = computed(() => {
  return store.getters['internalChat/getFavoriteChannels'] || [];
});

const dmChannels = computed(() => {
  return store.getters['internalChat/getDMChannels'] || [];
});

const activeChannelId = computed(() => {
  return Number(route.params.channelId) || null;
});

function getDMPeerMember(channel) {
  if (channel.channel_type !== 'dm') return null;
  const currentUserId = store.getters.getCurrentUser?.id;
  const members = channel.members || [];
  return members.find(m => m.user_id !== currentUserId) || null;
}

// Returns the member to use for avatar/name display in DM sidebar items
function getDMDisplayMember(channel) {
  if (channel.channel_type !== 'dm') return null;
  const peer = getDMPeerMember(channel);
  if (peer) return peer;
  // Self-DM: use first member (self). Deleted-user DM: no member to display.
  if (channel.name) return null;
  return (channel.members || [])[0] || null;
}

function isDeletedUserDM(channel) {
  if (channel.channel_type !== 'dm') return false;
  return !getDMPeerMember(channel) && !!channel.name;
}

function getDMDisplayName(channel) {
  if (channel.channel_type !== 'dm') return channel.name || '';
  const peer = getDMPeerMember(channel);
  if (peer) return peer.name;
  // No peer: either self-DM or deleted user DM (name stored on channel)
  return channel.name || (channel.members || [])[0]?.name || 'Direct Message';
}

function isSelfDM(channel) {
  if (channel.channel_type !== 'dm') return false;
  // DMs with a stored name are from deleted users, not self-DMs
  if (channel.name) return false;
  const currentUserId = store.getters.getCurrentUser?.id;
  const members = channel.members || [];
  return members.length > 0 && members.every(m => m.user_id === currentUserId);
}

function getDisplayName(channel) {
  if (channel.channel_type === 'dm') return getDMDisplayName(channel);
  return channel.name || '';
}

const filteredChannelsByCategory = computed(() => {
  return categoryId => {
    const categoryChannels =
      store.getters['internalChat/getChannelsByCategory'](categoryId) || [];
    return [...categoryChannels].sort((a, b) => {
      if (a.muted && !b.muted) return 1;
      if (!a.muted && b.muted) return -1;
      return 0;
    });
  };
});

const filteredDMChannels = computed(() => {
  return (dmChannels.value || []).filter(ch => !ch.hidden);
});

const filteredFavoriteChannels = computed(() => {
  return favoriteChannels.value || [];
});

const uncategorizedChannels = computed(() => {
  const uncategorized = channels.value.filter(
    ch =>
      ch.channel_type !== 'dm' && !ch.category_id && ch.status !== 'archived'
  );
  return [...uncategorized].sort((a, b) => {
    if (a.muted && !b.muted) return 1;
    if (!a.muted && b.muted) return -1;
    return 0;
  });
});

const isDraftsRoute = computed(() => {
  return route.name === 'internal_chat_drafts';
});

const draftCount = computed(() => {
  return (store.getters['internalChat/drafts/getDrafts'] || []).length;
});

const localUncategorizedChannels = ref([]);
const localCategoryChannels = ref({});

watch(
  uncategorizedChannels,
  val => {
    localUncategorizedChannels.value = [...val];
  },
  { immediate: true }
);

watch(
  () =>
    categories.value.map(cat => ({
      id: cat.id,
      channels: filteredChannelsByCategory.value(cat.id),
    })),
  newVal => {
    const map = {};
    newVal.forEach(({ id, channels: catChannels }) => {
      map[id] = [...catChannels];
    });
    localCategoryChannels.value = map;
  },
  { immediate: true }
);

function getCategoryChannelList(categoryId) {
  return localCategoryChannels.value[categoryId] || [];
}

function setCategoryChannelList(categoryId, list) {
  localCategoryChannels.value = {
    ...localCategoryChannels.value,
    [categoryId]: list,
  };
}

function onDragEnd(event) {
  const channelId = Number(event.item.dataset.channelId);
  const toCategoryId = event.to.dataset.categoryId || null;
  store.dispatch('internalChat/update', {
    channelId,
    channel: { category_id: toCategoryId ? Number(toCategoryId) : null },
  });
}

function navigateToChannel(channel) {
  const routeName =
    channel.channel_type === 'dm'
      ? 'internal_chat_dm'
      : 'internal_chat_channel';
  router.push({
    name: routeName,
    params: { accountId: accountId.value, channelId: channel.id },
  });
}

function navigateToDrafts() {
  router.push({
    name: 'internal_chat_drafts',
    params: { accountId: accountId.value },
  });
}

function getChannelIcon(channel) {
  if (channel.channel_type === 'dm') return 'i-lucide-message-circle';
  if (channel.channel_type === 'private_channel') return 'i-lucide-lock';
  return 'i-lucide-hash';
}

function openCreateChannel() {
  createChannelModalRef.value?.open();
}

function openCreateDM() {
  createDMModalRef.value?.open();
}

function openCreateCategory() {
  createCategoryModalRef.value?.open();
}

const deleteCategoryDialogRef = ref(null);
const pendingDeleteCategoryId = ref(null);

function confirmDeleteCategory(categoryId) {
  pendingDeleteCategoryId.value = categoryId;
  deleteCategoryDialogRef.value?.open();
}

async function handleDeleteCategory() {
  if (!pendingDeleteCategoryId.value) return;
  try {
    await store.dispatch(
      'internalChat/deleteCategory',
      pendingDeleteCategoryId.value
    );
  } catch {
    // error handled in store
  }
  pendingDeleteCategoryId.value = null;
  deleteCategoryDialogRef.value?.close();
}
</script>

<template>
  <div
    class="relative flex h-full w-full flex-col border-r border-n-slate-5 bg-n-solid-2 md:w-auto md:flex-shrink-0"
    :style="isSmallScreen ? undefined : { width: `${sidebarWidth}px` }"
  >
    <div class="px-3 pt-3 pb-1">
      <div class="mb-2 flex items-center justify-between gap-2">
        <h1 class="min-w-0 truncate text-base font-semibold text-n-slate-12">
          {{ t('INTERNAL_CHAT.TITLE') }}
        </h1>
        <button
          type="button"
          class="hidden flex-shrink-0 items-center justify-center rounded p-1 text-n-slate-11 transition-colors hover:bg-n-alpha-2 hover:text-n-slate-12 md:flex"
          :title="t('INTERNAL_CHAT.SIDEBAR.COLLAPSE')"
          :aria-label="t('INTERNAL_CHAT.SIDEBAR.COLLAPSE')"
          @click="collapse"
        >
          <Icon icon="i-lucide-panel-left-close" class="size-4" />
        </button>
      </div>
      <div
        class="flex h-7 items-center gap-1.5 rounded-lg bg-n-alpha-1 px-2 py-1"
      >
        <Icon
          icon="i-lucide-search"
          class="size-3.5 flex-shrink-0 text-n-slate-9"
        />
        <input
          v-model="searchQuery"
          type="text"
          :placeholder="t('INTERNAL_CHAT.SEARCH_PLACEHOLDER')"
          :aria-label="t('INTERNAL_CHAT.SEARCH_PLACEHOLDER')"
          class="reset-base min-w-0 flex-1 bg-transparent text-sm text-n-slate-12 placeholder-n-slate-10 outline-none"
        />
        <button
          v-if="searchQuery"
          type="button"
          class="flex-shrink-0 rounded p-0.5 text-n-slate-10 hover:text-n-slate-12"
          @click="clearSearch"
        >
          <Icon icon="i-lucide-x" class="size-3.5" />
        </button>
      </div>
    </div>
    <!-- Search Results -->
    <div v-if="isSearchMode" class="flex-1 overflow-y-auto px-1.5">
      <!-- Min characters hint -->
      <div
        v-if="!isSearchReady"
        class="flex flex-col items-center justify-center gap-1 px-4 py-12 text-center"
      >
        <fluent-icon icon="search" size="32" class="text-n-slate-8" />
        <p class="text-xs text-n-slate-9">
          {{ t('INTERNAL_CHAT.SEARCH.MIN_CHARS_HINT') }}
        </p>
      </div>
      <!-- Loading skeleton -->
      <div
        v-else-if="
          isSearchPending || (searchUIFlags.isFetching && !hasSearchResults)
        "
        class="space-y-4 pt-2"
      >
        <div v-for="section in 3" :key="section">
          <div class="mb-1 px-2 py-1">
            <div class="h-3 w-20 animate-pulse rounded bg-n-alpha-2" />
          </div>
          <div
            v-for="i in section === 3 ? 3 : 2"
            :key="i"
            class="flex animate-pulse items-center gap-2 rounded-lg px-2 py-1.5"
          >
            <div
              class="size-4 flex-shrink-0 bg-n-alpha-2"
              :class="section === 3 ? 'rounded-full' : 'rounded'"
            />
            <div
              class="h-3.5 flex-1 rounded bg-n-alpha-2"
              :style="{ maxWidth: `${50 + (i % 3) * 15}%` }"
            />
          </div>
        </div>
      </div>

      <!-- No results -->
      <div
        v-else-if="
          !isSearchPending && !searchUIFlags.isFetching && !hasSearchResults
        "
        class="flex flex-col items-center justify-center gap-2 px-4 py-12 text-center"
      >
        <fluent-icon icon="search" size="32" class="text-n-slate-8" />
        <p class="text-sm font-medium text-n-slate-11">
          {{ t('INTERNAL_CHAT.SEARCH.NO_RESULTS') }}
        </p>
        <p class="text-xs text-n-slate-9">
          {{ t('INTERNAL_CHAT.SEARCH.NO_RESULTS_SUBTITLE') }}
        </p>
      </div>

      <template v-else>
        <!-- Channel results -->
        <div v-if="searchChannels.length > 0" class="mb-3">
          <h3
            class="px-2 py-1 text-xs font-semibold uppercase tracking-wider text-n-slate-10"
          >
            {{ t('INTERNAL_CHAT.SEARCH.CHANNELS') }}
          </h3>
          <button
            v-for="channel in searchChannels"
            :key="`sc-${channel.id}`"
            class="flex w-full items-center gap-2 rounded-lg px-2 py-1.5 text-sm transition-colors"
            :class="
              activeChannelId === channel.id
                ? 'bg-n-alpha-2 text-n-slate-12'
                : 'text-n-slate-11 hover:bg-n-alpha-1 hover:text-n-slate-12'
            "
            @click="
              navigateToChannel({
                id: channel.id,
                channel_type: channel.channel_type,
              })
            "
          >
            <Icon
              :icon="getChannelIcon(channel)"
              class="size-4 flex-shrink-0"
            />
            <span class="flex-1 truncate text-left">{{ channel.name }}</span>
          </button>
        </div>

        <!-- DM results -->
        <div v-if="searchDMs.length > 0" class="mb-3">
          <h3
            class="px-2 py-1 text-xs font-semibold uppercase tracking-wider text-n-slate-10"
          >
            {{ t('INTERNAL_CHAT.SEARCH.DIRECT_MESSAGES') }}
          </h3>
          <button
            v-for="dm in searchDMs"
            :key="`sd-${dm.id}`"
            class="flex w-full items-center gap-2 rounded-lg px-2 py-1.5 text-sm transition-colors"
            :class="
              activeChannelId === dm.id
                ? 'bg-n-alpha-2 text-n-slate-12'
                : 'text-n-slate-11 hover:bg-n-alpha-1 hover:text-n-slate-12'
            "
            @click="
              navigateToChannel({ id: dm.id, channel_type: dm.channel_type })
            "
          >
            <Avatar
              :name="dm.peer?.name || ''"
              :src="dm.peer?.avatar_url || ''"
              :size="20"
              rounded-full
            />
            <span class="flex-1 truncate text-left">
              {{ dm.peer?.name || '' }}
            </span>
          </button>
        </div>

        <!-- Message results -->
        <div v-if="searchMessages.length > 0" class="mb-3">
          <h3
            class="px-2 py-1 text-xs font-semibold uppercase tracking-wider text-n-slate-10"
          >
            {{ t('INTERNAL_CHAT.SEARCH.MESSAGES') }}
          </h3>
          <div v-if="isSearchLimited" class="px-2 pb-2">
            <ProFeatureNudge feature="search" inline />
          </div>
          <button
            v-for="message in searchMessages"
            :key="`sm-${message.id}`"
            class="flex w-full flex-col gap-1 rounded-lg px-2 py-2 text-left transition-colors hover:bg-n-alpha-1"
            @click="navigateToMessage(message)"
          >
            <div class="flex items-center gap-2">
              <Avatar
                :name="message.sender?.name || ''"
                :src="message.sender?.avatar_url || ''"
                :size="16"
                rounded-full
              />
              <span class="flex-1 truncate text-sm font-medium text-n-slate-12">
                {{ message.sender?.name || '' }}
              </span>
              <span class="flex-shrink-0 text-xs text-n-slate-9">
                {{ formatMessageTime(message.created_at) }}
              </span>
            </div>
            <span
              class="line-clamp-2 text-xs text-n-slate-10"
              v-html="highlightMatch(message.content, searchQuery.trim())"
            />
            <span class="text-xs text-n-slate-9">
              {{
                message.channel_type === 'dm'
                  ? message.channel_name || ''
                  : `${t('INTERNAL_CHAT.CONVERSATION_MENTION.PREFIX')}${message.channel_name || ''}`
              }}
            </span>
          </button>
          <button
            v-if="searchUIFlags.hasMoreMessages"
            class="mt-1 flex w-full items-center justify-center gap-1 rounded-lg px-2 py-1.5 text-xs text-n-slate-10 transition-colors hover:bg-n-alpha-1 hover:text-n-slate-12"
            :disabled="searchUIFlags.isFetching"
            @click="loadMoreMessages"
          >
            {{ t('INTERNAL_CHAT.SEARCH.LOAD_MORE') }}
          </button>
        </div>
      </template>
    </div>

    <!-- Normal sidebar content -->
    <div v-show="!isSearchMode" class="px-1.5 pb-1">
      <button
        class="flex w-full items-center gap-2 rounded-lg px-2 py-1.5 text-sm transition-colors"
        :class="
          isDraftsRoute
            ? 'bg-n-alpha-2 text-n-slate-12'
            : 'text-n-slate-11 hover:bg-n-alpha-1 hover:text-n-slate-12'
        "
        @click="navigateToDrafts"
      >
        <Icon icon="i-lucide-file-edit" class="size-4 flex-shrink-0" />
        <span class="flex-1 text-left">{{
          t('INTERNAL_CHAT.DRAFT.TITLE')
        }}</span>
        <span
          v-if="draftCount > 0"
          class="flex-shrink-0 rounded-full bg-n-slate-8 px-1.5 py-0.5 text-xs font-medium text-white"
        >
          {{ draftCount }}
        </span>
      </button>
    </div>
    <div v-show="!isSearchMode" class="flex-1 overflow-y-auto px-1.5">
      <!-- Favorites -->
      <div v-if="filteredFavoriteChannels.length > 0" class="mb-3">
        <h3
          class="flex cursor-pointer items-center gap-1.5 px-2 py-1 text-xs font-semibold uppercase tracking-wider text-n-slate-10"
          @click="toggleSection('favorites')"
        >
          <Icon
            :icon="
              isSectionCollapsed('favorites')
                ? 'i-lucide-chevron-right'
                : 'i-lucide-chevron-down'
            "
            class="size-3"
          />
          <Icon icon="i-lucide-star" class="size-3" />
          {{ t('INTERNAL_CHAT.FAVORITES') }}
        </h3>
        <div v-show="!isSectionCollapsed('favorites')">
          <button
            v-for="channel in filteredFavoriteChannels"
            :key="`fav-${channel.id}`"
            class="flex w-full items-center gap-2 rounded-lg px-2 py-1.5 text-sm transition-colors"
            :class="
              activeChannelId === channel.id
                ? 'bg-n-alpha-2 text-n-slate-12'
                : 'text-n-slate-11 hover:bg-n-alpha-1 hover:text-n-slate-12'
            "
            @click="navigateToChannel(channel)"
          >
            <Avatar
              v-if="channel.channel_type === 'dm'"
              :name="getDMDisplayName(channel)"
              :src="getDMDisplayMember(channel)?.avatar_url || ''"
              :status="getDMDisplayMember(channel)?.availability_status"
              :size="20"
              rounded-full
              hide-offline-status
            />
            <Icon
              v-else
              :icon="getChannelIcon(channel)"
              class="size-4 flex-shrink-0"
            />
            <span class="flex-1 truncate text-left">
              {{ getDisplayName(channel) }}
              <span v-if="isSelfDM(channel)" class="text-xs text-n-slate-10">
                {{ t('INTERNAL_CHAT.CHANNEL.YOU') }}
              </span>
              <span
                v-else-if="isDeletedUserDM(channel)"
                class="text-xs text-n-slate-9 italic"
              >
                ({{ t('INTERNAL_CHAT.MESSAGE.DELETED_USER') }})
              </span>
            </span>
            <span
              v-if="channel.unread_count > 0"
              class="flex-shrink-0 flex items-center gap-0.5 rounded-full px-1.5 py-0.5 text-xs font-medium text-white"
              :class="channel.has_unread_mention ? 'bg-n-ruby-9' : 'bg-n-brand'"
            >
              <span v-if="channel.has_unread_mention">{{
                t('INTERNAL_CHAT.MENTION_BADGE')
              }}</span>
              {{ channel.unread_count }}
            </span>
          </button>
        </div>
      </div>

      <!-- Categories -->
      <div v-for="category in categories" :key="category.id" class="mb-3">
        <h3
          class="group/cat flex cursor-pointer items-center justify-between px-2 py-1 text-xs font-semibold uppercase tracking-wider text-n-slate-10"
          @click="toggleSection(`category-${category.id}`)"
        >
          <span class="flex items-center gap-1.5">
            <Icon
              :icon="
                isSectionCollapsed(`category-${category.id}`)
                  ? 'i-lucide-chevron-right'
                  : 'i-lucide-chevron-down'
              "
              class="size-3"
            />
            {{ category.name }}
          </span>
          <button
            v-if="isAdmin"
            class="text-n-slate-9 transition-opacity hover:text-n-ruby-11 md:opacity-0 md:group-hover/cat:opacity-100"
            @click.stop="confirmDeleteCategory(category.id)"
          >
            <Icon icon="i-lucide-trash-2" class="size-3" />
          </button>
        </h3>
        <div v-show="!isSectionCollapsed(`category-${category.id}`)">
          <Draggable
            :list="getCategoryChannelList(category.id)"
            :disabled="!isAdmin || isSmallScreen"
            group="channels"
            item-key="id"
            ghost-class="opacity-30"
            :data-category-id="category.id"
            @update:list="list => setCategoryChannelList(category.id, list)"
            @end="onDragEnd"
          >
            <template #item="{ element: channel }">
              <button
                :data-channel-id="channel.id"
                class="flex w-full items-center gap-2 rounded-lg px-2 py-1.5 text-sm transition-colors"
                :class="[
                  activeChannelId === channel.id
                    ? 'bg-n-alpha-2 text-n-slate-12'
                    : 'text-n-slate-11 hover:bg-n-alpha-1 hover:text-n-slate-12',
                  {
                    'opacity-50':
                      channel.muted || channel.status === 'archived',
                  },
                ]"
                @click="navigateToChannel(channel)"
              >
                <Icon
                  :icon="getChannelIcon(channel)"
                  class="size-4 flex-shrink-0"
                />
                <Icon
                  v-if="channel.status === 'archived'"
                  icon="i-lucide-archive"
                  class="size-3 flex-shrink-0 text-n-slate-9"
                />
                <Icon
                  v-if="channel.muted"
                  icon="i-lucide-bell-off"
                  class="size-3 flex-shrink-0 text-n-slate-9"
                />
                <span class="flex-1 truncate text-left">{{
                  channel.name
                }}</span>
                <span
                  v-if="channel.unread_count > 0"
                  class="flex-shrink-0 flex items-center gap-0.5 rounded-full px-1.5 py-0.5 text-xs font-medium text-white"
                  :class="
                    channel.has_unread_mention ? 'bg-n-ruby-9' : 'bg-n-brand'
                  "
                >
                  <span v-if="channel.has_unread_mention">{{
                    t('INTERNAL_CHAT.MENTION_BADGE')
                  }}</span>
                  {{ channel.unread_count }}
                </span>
              </button>
            </template>
          </Draggable>
        </div>
      </div>

      <div v-if="isAdmin" class="mb-3 px-2">
        <button
          class="flex items-center gap-1 text-xs text-n-slate-10 transition-colors hover:text-n-slate-12"
          @click="openCreateCategory"
        >
          <Icon icon="i-lucide-plus" class="size-3" />
          {{ t('INTERNAL_CHAT.CATEGORY.CREATE') }}
        </button>
      </div>

      <!-- Uncategorized channels -->
      <div class="mb-3">
        <h3
          class="flex cursor-pointer items-center justify-between px-2 py-1 text-xs font-semibold uppercase tracking-wider text-n-slate-10"
          @click="toggleSection('channels')"
        >
          <span class="flex items-center gap-1.5">
            <Icon
              :icon="
                isSectionCollapsed('channels')
                  ? 'i-lucide-chevron-right'
                  : 'i-lucide-chevron-down'
              "
              class="size-3"
            />
            {{ t('INTERNAL_CHAT.CHANNELS') }}
          </span>
          <button
            v-if="isAdmin"
            class="text-n-slate-10 transition-colors hover:text-n-slate-12"
            @click.stop="openCreateChannel"
          >
            <Icon icon="i-lucide-plus" class="size-3.5" />
          </button>
        </h3>
        <div v-show="!isSectionCollapsed('channels')">
          <Draggable
            :list="localUncategorizedChannels"
            :disabled="!isAdmin || isSmallScreen"
            group="channels"
            item-key="id"
            ghost-class="opacity-30"
            data-category-id=""
            @update:list="
              list => {
                localUncategorizedChannels = list;
              }
            "
            @end="onDragEnd"
          >
            <template #item="{ element: channel }">
              <button
                :data-channel-id="channel.id"
                class="flex w-full items-center gap-2 rounded-lg px-2 py-1.5 text-sm transition-colors"
                :class="[
                  activeChannelId === channel.id
                    ? 'bg-n-alpha-2 text-n-slate-12'
                    : 'text-n-slate-11 hover:bg-n-alpha-1 hover:text-n-slate-12',
                  {
                    'opacity-50':
                      channel.muted || channel.status === 'archived',
                  },
                ]"
                @click="navigateToChannel(channel)"
              >
                <Icon
                  :icon="getChannelIcon(channel)"
                  class="size-4 flex-shrink-0"
                />
                <Icon
                  v-if="channel.status === 'archived'"
                  icon="i-lucide-archive"
                  class="size-3 flex-shrink-0 text-n-slate-9"
                />
                <Icon
                  v-if="channel.muted"
                  icon="i-lucide-bell-off"
                  class="size-3 flex-shrink-0 text-n-slate-9"
                />
                <span class="flex-1 truncate text-left">{{
                  channel.name
                }}</span>
                <span
                  v-if="channel.unread_count > 0"
                  class="flex-shrink-0 flex items-center gap-0.5 rounded-full px-1.5 py-0.5 text-xs font-medium text-white"
                  :class="
                    channel.has_unread_mention ? 'bg-n-ruby-9' : 'bg-n-brand'
                  "
                >
                  <span v-if="channel.has_unread_mention">{{
                    t('INTERNAL_CHAT.MENTION_BADGE')
                  }}</span>
                  {{ channel.unread_count }}
                </span>
              </button>
            </template>
          </Draggable>
        </div>
      </div>

      <!-- Direct Messages -->
      <div class="mb-3">
        <h3
          class="flex cursor-pointer items-center justify-between px-2 py-1 text-xs font-semibold uppercase tracking-wider text-n-slate-10"
          @click="toggleSection('dm')"
        >
          <span class="flex items-center gap-1.5">
            <Icon
              :icon="
                isSectionCollapsed('dm')
                  ? 'i-lucide-chevron-right'
                  : 'i-lucide-chevron-down'
              "
              class="size-3"
            />
            <Icon icon="i-lucide-message-circle" class="size-3" />
            {{ t('INTERNAL_CHAT.DIRECT_MESSAGES') }}
          </span>
          <button
            class="text-n-slate-10 transition-colors hover:text-n-slate-12"
            @click.stop="openCreateDM"
          >
            <Icon icon="i-lucide-plus" class="size-3.5" />
          </button>
        </h3>
        <div v-show="!isSectionCollapsed('dm')">
          <button
            v-for="channel in filteredDMChannels"
            :key="`dm-${channel.id}`"
            class="flex w-full items-center gap-2 rounded-lg px-2 py-1.5 text-sm transition-colors"
            :class="[
              activeChannelId === channel.id
                ? 'bg-n-alpha-2 text-n-slate-12'
                : 'text-n-slate-11 hover:bg-n-alpha-1 hover:text-n-slate-12',
              { 'opacity-50': channel.muted },
            ]"
            @click="navigateToChannel(channel)"
          >
            <Avatar
              :name="getDMDisplayName(channel)"
              :src="getDMDisplayMember(channel)?.avatar_url || ''"
              :status="getDMDisplayMember(channel)?.availability_status"
              :size="20"
              rounded-full
              hide-offline-status
            />
            <Icon
              v-if="channel.status === 'archived'"
              icon="i-lucide-archive"
              class="size-3 flex-shrink-0 text-n-slate-9"
            />
            <Icon
              v-if="channel.muted"
              icon="i-lucide-bell-off"
              class="size-3 flex-shrink-0 text-n-slate-9"
            />
            <span class="flex-1 truncate text-left">
              {{ getDMDisplayName(channel) }}
              <span v-if="isSelfDM(channel)" class="text-xs text-n-slate-10">
                {{ t('INTERNAL_CHAT.CHANNEL.YOU') }}
              </span>
              <span
                v-else-if="isDeletedUserDM(channel)"
                class="text-xs text-n-slate-9 italic"
              >
                ({{ t('INTERNAL_CHAT.MESSAGE.DELETED_USER') }})
              </span>
            </span>
            <span
              v-if="channel.unread_count > 0"
              class="flex-shrink-0 flex items-center gap-0.5 rounded-full px-1.5 py-0.5 text-xs font-medium text-white"
              :class="channel.has_unread_mention ? 'bg-n-ruby-9' : 'bg-n-brand'"
            >
              <span v-if="channel.has_unread_mention">{{
                t('INTERNAL_CHAT.MENTION_BADGE')
              }}</span>
              {{ channel.unread_count }}
            </span>
          </button>
        </div>
      </div>

      <!-- Archived channels -->
      <div class="mb-3">
        <h3
          class="flex cursor-pointer items-center gap-1.5 px-2 py-1 text-xs font-semibold uppercase tracking-wider text-n-slate-10"
          @click="toggleArchivedSection"
        >
          <Icon
            :icon="
              showArchived ? 'i-lucide-chevron-down' : 'i-lucide-chevron-right'
            "
            class="size-3"
          />
          <Icon icon="i-lucide-archive" class="size-3" />
          {{ t('INTERNAL_CHAT.ARCHIVED.TITLE') }}
        </h3>
        <div v-if="showArchived">
          <div v-if="uiFlags.isFetchingArchived" class="space-y-1 px-2">
            <div
              v-for="i in 3"
              :key="`arch-skel-${i}`"
              class="flex animate-pulse items-center gap-2 rounded-lg px-2 py-1.5"
            >
              <div class="size-4 flex-shrink-0 rounded bg-n-alpha-2" />
              <div
                class="h-3.5 flex-1 rounded bg-n-alpha-2"
                :style="{ maxWidth: `${60 + (i % 3) * 20}%` }"
              />
            </div>
          </div>
          <div v-else-if="archivedChannels.length === 0" class="px-4 py-2">
            <p class="text-xs text-n-slate-9">
              {{ t('INTERNAL_CHAT.ARCHIVED.EMPTY') }}
            </p>
          </div>
          <template v-else>
            <button
              v-for="channel in archivedChannels"
              :key="`arch-${channel.id}`"
              class="flex w-full items-center gap-2 rounded-lg px-2 py-1.5 text-sm opacity-50 transition-colors"
              :class="[
                activeChannelId === channel.id
                  ? 'bg-n-alpha-2 text-n-slate-12'
                  : 'text-n-slate-11 hover:bg-n-alpha-1 hover:text-n-slate-12',
              ]"
              @click="navigateToChannel(channel)"
            >
              <Icon
                :icon="getChannelIcon(channel)"
                class="size-4 flex-shrink-0"
              />
              <Icon
                icon="i-lucide-archive"
                class="size-3 flex-shrink-0 text-n-slate-9"
              />
              <span class="flex-1 truncate text-left">{{
                channel.name || getDMDisplayName(channel)
              }}</span>
            </button>
          </template>
        </div>
      </div>

      <!-- Loading skeleton -->
      <div
        v-if="uiFlags.isFetching && channels.length === 0"
        class="space-y-1 px-2"
      >
        <div
          v-for="i in 6"
          :key="i"
          class="flex animate-pulse items-center gap-2 rounded-lg px-2 py-1.5"
        >
          <div class="size-4 flex-shrink-0 rounded bg-n-alpha-2" />
          <div
            class="h-3.5 flex-1 rounded bg-n-alpha-2"
            :style="{ maxWidth: `${60 + (i % 3) * 20}%` }"
          />
        </div>
      </div>

      <!-- Empty state -->
      <div
        v-else-if="!uiFlags.isFetching && channels.length === 0"
        class="flex items-center justify-center py-8"
      >
        <p class="text-sm text-n-slate-10">
          {{ t('INTERNAL_CHAT.NO_CHANNELS') }}
        </p>
      </div>
    </div>

    <!-- Resize handle (desktop only) -->
    <div
      class="absolute top-0 z-40 hidden h-full w-1 cursor-col-resize group ltr:right-0 rtl:left-0 md:block"
      role="separator"
      aria-orientation="vertical"
      tabindex="0"
      :aria-label="t('INTERNAL_CHAT.SIDEBAR.RESIZE')"
      :aria-valuenow="sidebarWidth"
      :aria-valuemin="MIN_WIDTH"
      :aria-valuemax="MAX_WIDTH"
      @mousedown="onResizeStart"
      @touchstart="onResizeStart"
      @dblclick="collapse"
      @keydown.left.prevent="nudgeWidth(-KEYBOARD_STEP)"
      @keydown.right.prevent="nudgeWidth(KEYBOARD_STEP)"
      @keydown.enter.prevent="collapse"
      @keydown.space.prevent="collapse"
    >
      <div
        class="absolute top-0 h-full w-px bg-transparent transition-colors group-hover:bg-n-brand ltr:right-0 rtl:left-0"
        :class="{ 'bg-n-brand': isResizing }"
      />
    </div>

    <CreateChannelModal ref="createChannelModalRef" />
    <CreateDMModal ref="createDMModalRef" />
    <CreateCategoryModal ref="createCategoryModalRef" />
    <Dialog
      ref="deleteCategoryDialogRef"
      type="alert"
      :title="t('INTERNAL_CHAT.CATEGORY.DELETE')"
      :description="t('INTERNAL_CHAT.CATEGORY.DELETE_DESCRIPTION')"
      :confirm-button-label="t('INTERNAL_CHAT.CATEGORY.DELETE')"
      @confirm="handleDeleteCategory"
    />
  </div>
</template>
