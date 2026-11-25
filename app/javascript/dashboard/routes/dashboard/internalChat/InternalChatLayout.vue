<script setup>
import { onMounted, computed } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import ChannelSidebar from './ChannelSidebar.vue';
import ChannelView from './ChannelView.vue';
import { useInternalChatSidebar } from 'dashboard/composables/useInternalChatSidebar';

const store = useStore();
const route = useRoute();
const { t } = useI18n();

const { isCollapsed, expand } = useInternalChatSidebar();

const activeChannelId = computed(() => {
  return Number(route.params.channelId) || null;
});

const activeChannel = computed(() => {
  if (!activeChannelId.value) return null;
  return store.getters['internalChat/getChannelById'](activeChannelId.value);
});

const isDraftsRoute = computed(() => {
  return route.name === 'internal_chat_drafts';
});

const hasActivePane = computed(() => {
  return Boolean(
    (activeChannelId.value && activeChannel.value) || isDraftsRoute.value
  );
});

// Below md the channel list is a screen of its own, so it gives way as soon as
// a channel (or the drafts view) is open. On desktop both columns coexist and
// the list only disappears when the user collapses it.
const sidebarDisplayClass = computed(() => {
  if (hasActivePane.value) {
    return isCollapsed.value ? 'hidden' : 'hidden md:flex';
  }
  return isCollapsed.value ? 'flex md:hidden' : 'flex';
});

async function fetchChannels() {
  try {
    await store.dispatch('internalChat/get');
  } catch {
    useAlert(t('INTERNAL_CHAT.ERRORS.FETCH_CHANNELS'));
  }
}

onMounted(async () => {
  await fetchChannels();
  // If navigated directly to a channel not in the store (e.g. archived), fetch it
  if (activeChannelId.value && !activeChannel.value) {
    store.dispatch('internalChat/show', activeChannelId.value).catch(() => {});
  }
  store.dispatch('agents/get');
  store.dispatch('teams/get');
});
</script>

<template>
  <div class="flex h-full w-full">
    <ChannelSidebar :class="sidebarDisplayClass" />
    <!-- Collapsed rail: lives here, and not in the channel header, so the list
    can be reopened from the empty state and the drafts view too. -->
    <div
      v-if="isCollapsed"
      class="hidden h-full w-9 flex-shrink-0 flex-col items-center border-r border-n-slate-5 bg-n-solid-2 pt-3 md:flex"
    >
      <button
        type="button"
        class="flex items-center justify-center rounded-lg p-1.5 text-n-slate-11 transition-colors hover:bg-n-alpha-2 hover:text-n-slate-12"
        :title="t('INTERNAL_CHAT.SIDEBAR.EXPAND')"
        :aria-label="t('INTERNAL_CHAT.SIDEBAR.EXPAND')"
        @click="expand"
      >
        <Icon icon="i-lucide-panel-left-open" class="size-4" />
      </button>
    </div>
    <div class="flex-1 min-w-0" :class="{ 'hidden md:block': !hasActivePane }">
      <ChannelView
        v-if="activeChannelId && activeChannel"
        :key="activeChannelId"
        :channel-id="activeChannelId"
      />
      <router-view v-else-if="isDraftsRoute" />
      <div
        v-else
        class="flex h-full flex-col items-center justify-center gap-2 bg-n-solid-1"
      >
        <Icon icon="i-lucide-messages-square" class="size-10 text-n-slate-8" />
        <p class="text-sm font-medium text-n-slate-12">
          {{ t('INTERNAL_CHAT.EMPTY_STATE.TITLE') }}
        </p>
        <p class="text-xs text-n-slate-10">
          {{ t('INTERNAL_CHAT.EMPTY_STATE.SUBTITLE') }}
        </p>
      </div>
    </div>
  </div>
</template>
