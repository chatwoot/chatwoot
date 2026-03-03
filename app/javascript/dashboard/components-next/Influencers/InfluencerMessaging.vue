<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';

const props = defineProps({
  profile: { type: Object, required: true },
});

const { t } = useI18n();
const store = useStore();

const conversations = ref([]);
const channels = ref({});
const loading = ref(false);
const sending = ref(false);
const sendError = ref('');
const messageContent = ref('');
const selectedInboxId = ref(null);
const showCompose = ref(false);

const availableChannels = computed(() =>
  Object.entries(channels.value)
    .map(([id, ch]) => ({ id: Number(id), ...ch }))
    .filter(ch => ch.available)
);

const unavailableChannels = computed(() =>
  Object.entries(channels.value)
    .map(([id, ch]) => ({ id: Number(id), ...ch }))
    .filter(ch => !ch.available)
);

const canSend = computed(
  () =>
    availableChannels.value.length > 0 &&
    selectedInboxId.value &&
    messageContent.value.trim()
);

const channelIcon = ch => {
  if (ch.channel_type === 'Channel::Instagram') return 'i-lucide-instagram';
  if (ch.channel_type === 'Channel::Email') return 'i-lucide-mail';
  return 'i-lucide-message-circle';
};

async function fetchConversations() {
  loading.value = true;
  try {
    const result = await store.dispatch('influencerProfiles/getConversations', {
      profileId: props.profile.id,
    });
    conversations.value = result.conversations || [];
    channels.value = result.channels || {};

    // Auto-select first available channel
    if (availableChannels.value.length && !selectedInboxId.value) {
      selectedInboxId.value = availableChannels.value[0].id;
    }
  } catch {
    conversations.value = [];
  } finally {
    loading.value = false;
  }
}

async function handleSend() {
  if (!canSend.value) return;
  sending.value = true;
  sendError.value = '';
  try {
    await store.dispatch('influencerProfiles/sendMessage', {
      profileId: props.profile.id,
      inboxId: selectedInboxId.value,
      content: messageContent.value.trim(),
    });
    messageContent.value = '';
    showCompose.value = false;
    await fetchConversations();
  } catch (err) {
    sendError.value =
      err?.response?.data?.error || err?.message || 'Failed to send message';
  } finally {
    sending.value = false;
  }
}

function openConversation(displayId) {
  const accountId =
    props.profile.account_id || store.getters.getCurrentAccountId;
  const url = `/app/accounts/${accountId}/conversations/${displayId}`;
  window.open(url, '_blank');
}

function formatTime(dateStr) {
  if (!dateStr) return '';
  const date = new Date(dateStr);
  const now = new Date();
  const diffMs = now - date;
  const diffDays = Math.floor(diffMs / 86400000);
  if (diffDays === 0) {
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  }
  if (diffDays < 7) return `${diffDays}d ago`;
  return date.toLocaleDateString();
}

onMounted(fetchConversations);
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<template>
  <div class="mb-6">
    <div class="mb-3 flex items-center justify-between">
      <h4 class="text-sm font-semibold text-n-slate-12">
        {{ t('INFLUENCER.MESSAGING.TITLE') }}
      </h4>
      <button
        v-if="!showCompose && availableChannels.length"
        class="flex items-center gap-1 rounded-lg bg-n-brand px-3 py-1.5 text-xs font-medium text-white hover:opacity-90"
        @click="showCompose = true"
      >
        <span class="i-lucide-send size-3" />
        {{ t('INFLUENCER.MESSAGING.NEW_MESSAGE') }}
      </button>
    </div>

    <!-- No channels available -->
    <div
      v-if="!loading && !availableChannels.length && unavailableChannels.length"
      class="mb-3 space-y-1.5"
    >
      <div
        v-for="ch in unavailableChannels"
        :key="ch.id"
        class="flex items-center gap-2 rounded-lg bg-n-amber-2 px-3 py-2 text-xs text-n-amber-11"
      >
        <span :class="channelIcon(ch)" class="size-3.5 flex-shrink-0" />
        <span>{{ ch.name }}: {{ ch.reason }}</span>
      </div>
    </div>

    <!-- Compose box -->
    <div
      v-if="showCompose"
      class="mb-4 rounded-lg border border-n-weak bg-n-background p-3"
    >
      <!-- Inbox selector -->
      <div class="mb-3">
        <label class="mb-1 block text-xs text-n-slate-11">
          {{ t('INFLUENCER.MESSAGING.SEND_VIA') }}
        </label>
        <div class="flex flex-wrap gap-2">
          <button
            v-for="ch in availableChannels"
            :key="ch.id"
            class="flex items-center gap-1.5 rounded-lg border px-3 py-1.5 text-xs font-medium transition-colors"
            :class="
              selectedInboxId === ch.id
                ? 'border-n-brand bg-n-brand/10 text-n-brand'
                : 'border-n-weak text-n-slate-11 hover:bg-n-slate-2'
            "
            @click="selectedInboxId = ch.id"
          >
            <span :class="channelIcon(ch)" class="size-3.5" />
            {{ ch.name }}
          </button>
        </div>
      </div>

      <!-- Message textarea -->
      <textarea
        v-model="messageContent"
        rows="3"
        class="mb-2 w-full resize-none rounded-lg border border-n-weak bg-n-solid-1 px-3 py-2 text-sm text-n-slate-12 placeholder:text-n-slate-9 focus:border-n-brand focus:outline-none"
        :placeholder="t('INFLUENCER.MESSAGING.PLACEHOLDER')"
      />

      <div class="flex items-center justify-between">
        <button
          class="text-xs text-n-slate-11 hover:text-n-slate-12"
          @click="showCompose = false"
        >
          {{ t('INFLUENCER.MESSAGING.CANCEL') }}
        </button>
        <button
          class="flex items-center gap-1 rounded-lg bg-n-brand px-4 py-1.5 text-xs font-medium text-white hover:opacity-90 disabled:opacity-50"
          :disabled="sending || !canSend"
          @click="handleSend"
        >
          <span v-if="sending" class="i-lucide-loader-2 size-3 animate-spin" />
          <span v-else class="i-lucide-send size-3" />
          {{
            sending
              ? t('INFLUENCER.MESSAGING.SENDING')
              : t('INFLUENCER.MESSAGING.SEND')
          }}
        </button>
      </div>
      <p v-if="sendError" class="mt-2 text-xs text-red-600">
        {{ sendError }}
      </p>
    </div>

    <!-- Conversations list -->
    <div v-if="loading" class="py-4 text-center text-xs text-n-slate-10">
      <span
        class="i-lucide-loader-2 mr-1 inline-block size-3 animate-spin align-text-bottom"
      />
      {{ t('INFLUENCER.MESSAGING.LOADING') }}
    </div>

    <div v-else-if="conversations.length" class="space-y-2">
      <div
        v-for="conv in conversations"
        :key="conv.id"
        class="flex cursor-pointer items-center gap-3 rounded-lg border border-n-weak p-3 transition-colors hover:bg-n-background"
        @click="openConversation(conv.display_id)"
      >
        <span
          :class="channelIcon(conv.inbox)"
          class="size-4 flex-shrink-0 text-n-slate-11"
        />
        <div class="min-w-0 flex-1">
          <div class="flex items-center justify-between gap-2">
            <span class="text-xs font-medium text-n-slate-12">
              {{ conv.inbox.name }}
            </span>
            <span class="flex-shrink-0 text-[11px] text-n-slate-10">
              {{ formatTime(conv.last_activity_at) }}
            </span>
          </div>
          <p
            v-if="conv.last_message"
            class="mt-0.5 truncate text-xs text-n-slate-11"
          >
            {{ conv.last_message.content }}
          </p>
        </div>
        <span
          class="i-lucide-external-link size-3 flex-shrink-0 text-n-slate-10"
        />
      </div>
    </div>

    <p
      v-else-if="!loading && !showCompose"
      class="py-2 text-xs text-n-slate-10"
    >
      {{ t('INFLUENCER.MESSAGING.NO_CONVERSATIONS') }}
    </p>
  </div>
</template>
