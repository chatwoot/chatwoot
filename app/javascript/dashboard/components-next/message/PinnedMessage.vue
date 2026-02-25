<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import NextButton from 'dashboard/components-next/button/Button.vue';
import messageAPI from 'dashboard/api/inbox/message';
import { useAlert } from 'dashboard/composables';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

const props = defineProps({
  message: {
    type: Object,
    required: true,
  },
  conversationId: {
    type: Number,
    required: true,
  },
});

const { t } = useI18n();
const { getPlainText } = useMessageFormatter();
const store = useStore();

const messageContent = computed(() => {
  if (!props.message?.content) return '';
  try {
    const plainText = getPlainText(props.message.content);
    return plainText.length > 150
      ? `${plainText.substring(0, 150)}...`
      : plainText;
  } catch {
    return (
      props.message.content.substring(0, 150) +
      (props.message.content.length > 150 ? '...' : '')
    );
  }
});

const senderName = computed(() => {
  // Check sender object first
  if (props.message?.sender) {
    return props.message.sender.name || props.message.sender.available_name;
  }
  // Fallback to unknown
  return t('CONVERSATION.PINNED_MESSAGE.UNKNOWN_SENDER');
});

const messageTimestamp = computed(() => {
  if (!props.message?.created_at) return '';
  const date = new Date(props.message.created_at * 1000);
  return date.toLocaleString('en-US', {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
});

async function handleUnpin() {
  try {
    await messageAPI.unpinMessage(props.conversationId, props.message.id);
    // Reload conversation to get updated pinned_message
    await store.dispatch('getConversation', props.conversationId);
    useAlert(t('CONVERSATION.CONTEXT_MENU.UNPIN_SUCCESS'));
  } catch (error) {
    useAlert(t('CONVERSATION.CONTEXT_MENU.UNPIN_ERROR'));
  }
}
</script>

<template>
  <div
    class="flex items-start gap-4 p-4 mx-0 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-700 rounded-md shadow-sm"
  >
    <!-- Pin Icon Circle -->
    <div class="flex-shrink-0">
      <div
        class="w-10 h-10 rounded-full bg-yellow-500 dark:bg-yellow-600 flex items-center justify-center shadow-sm"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="w-5 h-5 text-white"
          viewBox="0 0 24 24"
          fill="currentColor"
        >
          <path
            d="M16 9V4h1c.55 0 1-.45 1-1s-.45-1-1-1H7c-.55 0-1 .45-1 1s.45 1 1 1h1v5c0 1.66-1.34 3-3 3v2h5.97v7l1 1 1-1v-7H19v-2c-1.66 0-3-1.34-3-3z"
          />
        </svg>
      </div>
    </div>

    <!-- Content Section -->
    <div class="flex-1 min-w-0 pt-0.5">
      <!-- Header: Label + Timestamp -->
      <div class="flex items-baseline gap-3 mb-2">
        <h3
          class="text-sm font-bold text-yellow-900 dark:text-yellow-200 uppercase tracking-wide"
        >
          {{ $t('CONVERSATION.PINNED_MESSAGE.LABEL') }}
        </h3>
        <span class="text-xs text-slate-500 dark:text-slate-400">
          {{ messageTimestamp }}
        </span>
      </div>

      <!-- Author Name -->
      <div class="text-sm font-semibold text-slate-900 dark:text-slate-50 mb-1">
        {{ senderName }}
      </div>

      <!-- Message Content Preview -->
      <p
        class="text-sm text-slate-700 dark:text-slate-300 line-clamp-2 break-words"
      >
        {{ messageContent }}
      </p>
    </div>

    <!-- Close Button -->
    <NextButton
      ghost
      sm
      icon="i-lucide-x"
      class="flex-shrink-0 text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200 hover:bg-yellow-100 dark:hover:bg-yellow-800/50"
      :title="$t('CONVERSATION.PINNED_MESSAGE.UNPIN')"
      @click="handleUnpin"
    />
  </div>
</template>
