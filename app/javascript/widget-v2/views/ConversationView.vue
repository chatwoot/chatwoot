<script setup>
import { computed, nextTick, onMounted, ref, watch } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useConfigStore } from 'widget-v2/stores/config';
import { useConversationsStore } from 'widget-v2/stores/conversations';
import { useMessagesStore } from 'widget-v2/stores/messages';
import { getAiState } from 'widget-v2/helpers/conversationHelpers';
import { useAvailability } from 'widget-v2/composables/useAvailability';
import WidgetHeader from 'widget-v2/components/WidgetHeader.vue';
import AiStateBanner from 'widget-v2/components/AiStateBanner.vue';
import MessageBubble from 'widget-v2/components/MessageBubble.vue';
import MessageComposer from 'widget-v2/components/MessageComposer.vue';
import TypingIndicator from 'widget-v2/components/TypingIndicator.vue';
import BrandingFooter from 'widget-v2/components/BrandingFooter.vue';
import BaseSpinner from 'widget-v2/components/base/BaseSpinner.vue';

const route = useRoute();
const { t } = useI18n();
const configStore = useConfigStore();
const conversationsStore = useConversationsStore();
const messagesStore = useMessagesStore();

const displayId = computed(() => Number(route.params.id));
const conversation = computed(() => conversationsStore.byId[displayId.value]);
const thread = computed(() => messagesStore.threads[displayId.value]);
const messages = computed(() =>
  (thread.value?.messages || []).filter(
    message => message.message_type !== 2 && !message.private
  )
);

const aiState = computed(() =>
  getAiState(conversation.value, configStore.hasAiAgent)
);

const headerTitle = computed(() => {
  if (aiState.value === 'ai') {
    return configStore.aiAgent?.name || t('AI_STATE.AI_DEFAULT_NAME');
  }
  return (
    conversation.value?.assignee?.name || configStore.channel.website_name || ''
  );
});

const { isOnline } = useAvailability();

const headerSubtitle = computed(() => {
  if (aiState.value === 'ai') return t('AVAILABILITY.ONLINE');
  return isOnline.value ? t('AVAILABILITY.ONLINE') : t('AVAILABILITY.AWAY');
});

const isAgentTyping = computed(() =>
  Boolean(conversationsStore.typingIn[displayId.value])
);

// Until the bot emits real typing events, infer "thinking" from an unanswered
// visitor message in an AI-owned conversation.
const isAiThinking = computed(() => {
  if (aiState.value !== 'ai') return false;
  const last = messages.value[messages.value.length - 1];
  return last?.message_type === 0 && last.status !== 'failed';
});

const composerDisabled = computed(
  () =>
    conversation.value?.status === 'resolved' &&
    configStore.channel.allow_messages_after_resolved === false
);

const scrollRef = ref(null);
const scrollToBottom = async () => {
  await nextTick();
  if (scrollRef.value) scrollRef.value.scrollTop = scrollRef.value.scrollHeight;
};

const showMeta = index => {
  const current = messages.value[index];
  const next = messages.value[index + 1];
  if (!next) return true;
  return (
    next.message_type !== current.message_type ||
    next.sender?.id !== current.sender?.id
  );
};

onMounted(async () => {
  if (!conversation.value) {
    await conversationsStore.loadOne(displayId.value).catch(() => {});
  }
  await messagesStore.load(displayId.value);
  conversationsStore.markSeen(displayId.value);
  scrollToBottom();
});

watch(
  () => messages.value.length,
  () => {
    scrollToBottom();
    conversationsStore.markSeen(displayId.value);
  }
);

const loadEarlier = () => {
  const [first] = messages.value;
  if (first) messagesStore.load(displayId.value, { before: first.id });
};

const onSend = content =>
  messagesStore.send(displayId.value, content).catch(() => {});
const onAttach = file =>
  messagesStore.sendAttachment(displayId.value, file).catch(() => {});
const onTyping = status =>
  conversationsStore.notifyTyping(displayId.value, status);
</script>

<template>
  <div class="flex flex-col h-full bg-cw-solid">
    <WidgetHeader :title="headerTitle" :subtitle="headerSubtitle" show-back />
    <AiStateBanner
      v-if="conversation"
      :ai-state="aiState"
      :assignee="conversation.assignee"
    />

    <div
      ref="scrollRef"
      class="flex-1 overflow-y-auto scrollbar-thin py-4 flex flex-col gap-2"
    >
      <div
        v-if="thread?.loading && !messages.length"
        class="flex justify-center py-8"
      >
        <BaseSpinner />
      </div>

      <button
        v-if="!thread?.allFetched && messages.length && !thread?.loading"
        type="button"
        class="self-center text-xs font-medium text-cw-text-muted hover:text-cw-text py-1 px-3 rounded-full outline-none focus-visible:ring-[3px] focus-visible:ring-cw-ring"
        @click="loadEarlier"
      >
        {{ $t('CONVERSATION.LOAD_EARLIER') }}
      </button>

      <MessageBubble
        v-for="(message, index) in messages"
        :key="message.id"
        :message="message"
        :show-meta="showMeta(index)"
      />

      <TypingIndicator
        v-if="isAgentTyping || isAiThinking"
        :label="isAiThinking && !isAgentTyping ? $t('AI.THINKING') : ''"
      />
    </div>

    <p
      v-if="conversation?.status === 'resolved' && !composerDisabled"
      class="px-4 py-2 text-xs text-center text-cw-text-muted bg-cw-surface border-t border-cw-hairline"
    >
      {{ $t('CONVERSATION.RESOLVED_NOTICE') }}
    </p>

    <MessageComposer
      v-if="!composerDisabled"
      :placeholder="aiState === 'ai' ? $t('AI.NEW_CHAT') : ''"
      @send="onSend"
      @attach="onAttach"
      @typing-on="onTyping('on')"
      @typing-off="onTyping('off')"
    />
    <BrandingFooter />
  </div>
</template>
