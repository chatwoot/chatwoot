<script setup>
import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useRoute, useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const store = useStore();
const { t } = useI18n();
const route = useRoute();
const router = useRouter();

const accountId = computed(() => route.params.accountId);
const currentUserId = computed(() => store.getters.getCurrentUser?.id);

const drafts = computed(() => {
  return store.getters['internalChat/drafts/getDrafts'] || [];
});

const uiFlags = computed(() => {
  return store.getters['internalChat/drafts/getUIFlags'];
});

// Below md the channel list and this view are separate screens.
function goBackToChannels() {
  router.push({
    name: 'internal_chat_home',
    params: { accountId: accountId.value },
  });
}

function timeSince(dateString) {
  const date = new Date(dateString);
  const now = new Date();
  const seconds = Math.floor((now - date) / 1000);

  if (seconds < 60) return t('INTERNAL_CHAT.DRAFT.SAVED_AGO', { time: '< 1m' });
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60)
    return t('INTERNAL_CHAT.DRAFT.SAVED_AGO', { time: `${minutes}m` });
  const hours = Math.floor(minutes / 60);
  if (hours < 24)
    return t('INTERNAL_CHAT.DRAFT.SAVED_AGO', { time: `${hours}h` });
  const days = Math.floor(hours / 24);
  return t('INTERNAL_CHAT.DRAFT.SAVED_AGO', { time: `${days}d` });
}

function getChannelName(draft) {
  const channel = store.getters['internalChat/getChannelById'](
    draft.internal_chat_channel_id
  );
  if (!channel) {
    return t('INTERNAL_CHAT.DRAFT.CHANNEL_LABEL', {
      channelId: draft.internal_chat_channel_id,
    });
  }
  if (channel.channel_type === 'dm') {
    const members = channel.members || [];
    const peer =
      members.find(m => m.user_id !== currentUserId.value) || members[0];
    return peer?.name || channel.name || t('INTERNAL_CHAT.DIRECT_MESSAGES');
  }
  return (
    channel.name ||
    t('INTERNAL_CHAT.DRAFT.CHANNEL_LABEL', {
      channelId: draft.internal_chat_channel_id,
    })
  );
}

function navigateToChannel(draft) {
  const channel = store.getters['internalChat/getChannelById'](
    draft.internal_chat_channel_id
  );
  const routeName =
    channel?.channel_type === 'dm'
      ? 'internal_chat_dm'
      : 'internal_chat_channel';
  const query = draft.parent_id
    ? { messageId: draft.parent_id, openThread: 1 }
    : {};
  router.push({
    name: routeName,
    params: {
      accountId: accountId.value,
      channelId: draft.internal_chat_channel_id,
    },
    query,
  });
}

async function handleDelete(draft) {
  try {
    await store.dispatch('internalChat/drafts/deleteDraft', {
      channelId: draft.internal_chat_channel_id,
      draftId: draft.id,
      parentId: draft.parent_id,
    });
  } catch {
    useAlert(t('INTERNAL_CHAT.ERRORS.SEND_MESSAGE'));
  }
}

onMounted(() => {
  store.dispatch('internalChat/drafts/fetchDrafts').catch(() => {
    // Silently handle fetch error
  });
});
</script>

<template>
  <div class="flex h-full flex-col bg-n-solid-1">
    <div
      class="flex h-[53px] items-center border-b border-n-slate-5 bg-n-solid-2 px-4"
    >
      <button
        type="button"
        class="mr-1 flex flex-shrink-0 items-center justify-center rounded-lg p-1.5 text-n-slate-11 transition-colors hover:bg-n-alpha-2 hover:text-n-slate-12 md:hidden"
        :title="t('INTERNAL_CHAT.BACK')"
        :aria-label="t('INTERNAL_CHAT.BACK')"
        @click="goBackToChannels"
      >
        <Icon icon="i-lucide-arrow-left" class="size-4" />
      </button>
      <Icon icon="i-lucide-file-edit" class="mr-2 size-5 text-n-slate-11" />
      <h2 class="text-sm font-semibold text-n-slate-12">
        {{ t('INTERNAL_CHAT.DRAFT.TITLE') }}
      </h2>
    </div>

    <div class="flex-1 overflow-y-auto">
      <div
        v-if="uiFlags.isFetching"
        class="flex items-center justify-center py-8"
      >
        <Spinner :size="16" />
      </div>

      <div
        v-else-if="drafts.length === 0"
        class="flex h-full flex-col items-center justify-center gap-2"
      >
        <Icon icon="i-lucide-file-edit" class="size-10 text-n-slate-8" />
        <p class="text-sm font-medium text-n-slate-12">
          {{ t('INTERNAL_CHAT.DRAFT.NO_DRAFTS') }}
        </p>
        <p class="text-xs text-n-slate-10">
          {{ t('INTERNAL_CHAT.DRAFT.NO_DRAFTS_SUBTITLE') }}
        </p>
      </div>

      <div v-else class="divide-y divide-n-slate-5">
        <div
          v-for="draft in drafts"
          :key="draft.id"
          class="flex items-start gap-3 px-4 py-3 hover:bg-n-alpha-1 transition-colors cursor-pointer"
          @click="navigateToChannel(draft)"
        >
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2">
              <span class="text-sm font-medium text-n-slate-12 truncate">
                {{ getChannelName(draft) }}
              </span>
              <span
                v-if="draft.parent_id"
                class="flex items-center gap-0.5 text-xs text-n-slate-10"
              >
                <Icon icon="i-lucide-message-square" class="size-3" />
                {{ t('INTERNAL_CHAT.THREAD.TITLE') }}
              </span>
              <span class="text-xs text-n-slate-10">
                {{ timeSince(draft.updated_at) }}
              </span>
            </div>
            <p class="mt-0.5 text-sm text-n-slate-10 truncate">
              {{ draft.content }}
            </p>
          </div>
          <button
            class="flex-shrink-0 flex items-center justify-center rounded p-1 text-n-slate-11 hover:bg-n-ruby-3 hover:text-n-ruby-11"
            :title="t('INTERNAL_CHAT.DRAFT.DELETE')"
            @click.stop="handleDelete(draft)"
          >
            <Icon icon="i-lucide-trash-2" class="size-4" />
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
