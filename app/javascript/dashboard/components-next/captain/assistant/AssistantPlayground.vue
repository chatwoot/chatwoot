<script setup>
import { computed, reactive, ref, toRef, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { usePolicy } from 'dashboard/composables/usePolicy';
import MessageList from './MessageList.vue';
import PlaygroundTestSetup from './PlaygroundTestSetup.vue';
import { usePlaygroundSession } from './usePlaygroundSession';
import CaptainAssistant from 'dashboard/api/captain/assistant';

const props = defineProps({
  assistantId: {
    type: Number,
    required: true,
  },
});

const { t } = useI18n();
const { isFeatureFlagEnabled } = usePolicy();
const isV2 = computed(() => isFeatureFlagEnabled(FEATURE_FLAGS.CAPTAIN_V2));
const messages = ref([]);
const newMessage = ref('');
const isLoading = ref(false);
const isSetupOpen = ref(true);
let conversationVersion = 0;

const session = reactive(
  usePlaygroundSession({
    assistantId: toRef(props, 'assistantId'),
  })
);

const formatMessagesForApi = () => {
  return messages.value
    .filter(message => !message.isError)
    .map(message => {
      const payload = {
        role: message.sender,
        content: message.content,
      };

      if (message.sender === 'assistant' && message.agentName) {
        payload.agent_name = message.agentName;
      }

      return payload;
    });
};

const resetConversation = () => {
  conversationVersion += 1;
  messages.value = [];
  newMessage.value = '';
  isLoading.value = false;
};

const resetTestSetup = async () => {
  resetConversation();
  await session.reset();
};

// Watch for assistant ID changes and reset conversation
watch(
  () => props.assistantId,
  (newId, oldId) => {
    if (oldId && newId !== oldId) {
      resetConversation();
      if (isV2.value) {
        isSetupOpen.value = true;
        session.reset();
      }
    }
  }
);

watch(
  isV2,
  enabled => {
    if (enabled) session.initialize();
  },
  { immediate: true }
);

const sendMessage = async () => {
  if (
    !newMessage.value.trim() ||
    isLoading.value ||
    (isV2.value && session.isInitializing)
  ) {
    return;
  }
  if (isV2.value && session.loadError) {
    messages.value.push({
      content: session.loadError,
      sender: 'assistant',
      isError: true,
      timestamp: new Date().toISOString(),
    });
    return;
  }
  if (isV2.value && !session.isValid) {
    messages.value.push({
      content: t('CAPTAIN.PLAYGROUND.SETUP.INVALID_CONFIGURATION'),
      sender: 'assistant',
      isError: true,
      timestamp: new Date().toISOString(),
    });
    return;
  }

  const userMessage = {
    content: newMessage.value,
    sender: 'user',
    timestamp: new Date().toISOString(),
  };
  messages.value.push(userMessage);
  const currentMessage = newMessage.value;
  const requestVersion = conversationVersion;
  const setupSummary = isV2.value ? session.configurationSummary() : undefined;
  newMessage.value = '';

  try {
    isLoading.value = true;
    const { data } = await CaptainAssistant.playground({
      assistantId: props.assistantId,
      messageContent: currentMessage,
      messageHistory: formatMessagesForApi(),
      playgroundConfig: isV2.value ? session.playgroundConfig : undefined,
    });
    if (requestVersion !== conversationVersion) return;

    messages.value.push({
      content: data.error
        ? t('CAPTAIN.PLAYGROUND.RESPONSE_ERROR')
        : data.response,
      sender: 'assistant',
      agentName: data.agent_name,
      runDetails: data.run_details,
      setupSummary,
      isError: Boolean(data.error),
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    if (requestVersion !== conversationVersion) return;

    messages.value.push({
      content:
        error?.response?.data?.error ||
        error?.response?.data?.message ||
        t('CAPTAIN.PLAYGROUND.RESPONSE_ERROR'),
      sender: 'assistant',
      isError: true,
      timestamp: new Date().toISOString(),
    });
  } finally {
    if (requestVersion === conversationVersion) isLoading.value = false;
  }
};

const handleEnterKey = event => {
  if (event.isComposing) return;
  event.preventDefault();
  sendMessage();
};
</script>

<template>
  <div
    class="h-full rounded-xl border border-n-weak text-n-slate-11"
    :class="isV2 ? 'relative flex overflow-hidden' : 'flex flex-col'"
  >
    <div class="flex min-w-0 flex-1 flex-col py-6">
      <div class="mb-8 px-6">
        <div class="mb-1 flex items-center justify-between gap-3">
          <h3 class="text-lg font-medium">
            {{ t('CAPTAIN.PLAYGROUND.HEADER') }}
          </h3>
          <div class="flex items-center gap-1">
            <NextButton
              ghost
              sm
              slate
              icon="i-lucide-rotate-ccw"
              :aria-label="t('CAPTAIN.PLAYGROUND.CLEAR_CONVERSATION')"
              @click="resetConversation"
            />
            <NextButton
              v-if="isV2"
              ghost
              sm
              slate
              icon="i-lucide-settings-2"
              :aria-label="t('CAPTAIN.PLAYGROUND.SETUP.TOGGLE')"
              @click="isSetupOpen = !isSetupOpen"
            />
          </div>
        </div>
        <p class="text-sm text-n-slate-11">
          {{ t('CAPTAIN.PLAYGROUND.DESCRIPTION') }}
        </p>
      </div>

      <MessageList :messages="messages" :is-loading="isLoading" />

      <div
        class="mx-6 flex items-center rounded-xl bg-n-background p-3 outline outline-1 outline-n-weak"
      >
        <input
          v-model="newMessage"
          class="mb-0 flex-1 border-none bg-transparent text-sm text-n-slate-12 placeholder:text-n-slate-10 focus:outline-none"
          :placeholder="t('CAPTAIN.PLAYGROUND.MESSAGE_PLACEHOLDER')"
          @keydown.enter.exact="handleEnterKey"
        />
        <NextButton
          ghost
          sm
          :disabled="
            !newMessage.trim() ||
            (isV2 && (session.isInitializing || Boolean(session.loadError)))
          "
          icon="i-lucide-send"
          :aria-label="t('CAPTAIN.PLAYGROUND.SEND_MESSAGE')"
          @click="sendMessage"
        />
      </div>

      <p class="pt-2 text-center text-xs text-n-slate-11">
        {{ t('CAPTAIN.PLAYGROUND.CREDIT_NOTE') }}
      </p>
    </div>

    <div
      v-if="isV2 && isSetupOpen"
      aria-hidden="true"
      class="fixed inset-0 z-30 bg-n-alpha-black2 lg:hidden"
      @click="isSetupOpen = false"
    />
    <div
      v-if="isV2 && isSetupOpen"
      class="fixed inset-y-0 end-0 z-40 w-full max-w-lg lg:static lg:z-auto lg:w-[38rem] lg:max-w-none lg:flex-none"
    >
      <PlaygroundTestSetup
        :session="session"
        @close="isSetupOpen = false"
        @reset="resetTestSetup"
      />
    </div>
  </div>
</template>
