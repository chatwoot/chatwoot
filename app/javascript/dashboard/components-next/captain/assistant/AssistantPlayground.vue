<script setup>
import { computed, reactive, ref, toRef, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { breakpointsTailwind, useBreakpoints } from '@vueuse/core';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SidePanel from 'dashboard/components-next/side-panel/SidePanel.vue';
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
const isBelowXL = useBreakpoints(breakpointsTailwind).smaller('xl');

const messages = ref([]);
const newMessage = ref('');
const isLoading = ref(false);
const isSetupOpen = ref(true);
const setupPanelRef = ref(null);
const setupInstanceKey = ref(0);
let conversationVersion = 0;

const session = reactive(
  usePlaygroundSession({
    assistantId: toRef(props, 'assistantId'),
  })
);

const isSendDisabled = computed(
  () =>
    !newMessage.value.trim() ||
    (isV2.value && (session.isInitializing || Boolean(session.loadError)))
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

const pushAssistantError = content => {
  messages.value.push({
    content,
    sender: 'assistant',
    isError: true,
    timestamp: new Date().toISOString(),
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
  setupInstanceKey.value += 1;
  await session.reset();
};

const toggleSetup = () => {
  if (isBelowXL.value) {
    setupPanelRef.value?.open();
  } else {
    isSetupOpen.value = !isSetupOpen.value;
  }
};

watch(
  () => props.assistantId,
  (newId, oldId) => {
    if (oldId && newId !== oldId) {
      resetConversation();
      setupInstanceKey.value += 1;
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
    pushAssistantError(session.loadError);
    return;
  }
  if (isV2.value && !session.isValid) {
    pushAssistantError(t('CAPTAIN.PLAYGROUND.SETUP.INVALID_CONFIGURATION'));
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

    pushAssistantError(
      error?.response?.data?.error ||
        error?.response?.data?.message ||
        t('CAPTAIN.PLAYGROUND.RESPONSE_ERROR')
    );
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
    :class="isV2 ? 'flex overflow-hidden' : 'flex flex-col'"
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
              @click="toggleSetup"
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
          :disabled="isSendDisabled"
          icon="i-lucide-send"
          :aria-label="t('CAPTAIN.PLAYGROUND.SEND_MESSAGE')"
          @click="sendMessage"
        />
      </div>

      <p class="pt-2 text-center text-xs text-n-slate-11">
        {{ t('CAPTAIN.PLAYGROUND.CREDIT_NOTE') }}
      </p>
    </div>

    <aside
      v-if="isV2 && isSetupOpen && !isBelowXL"
      aria-labelledby="playground-test-setup-title"
      class="flex w-[36rem] flex-none flex-col border-s border-n-weak bg-n-surface-1 text-n-slate-12"
    >
      <div
        class="flex items-start justify-between gap-3 border-b border-n-weak p-5"
      >
        <div>
          <h3 id="playground-test-setup-title" class="text-base font-medium">
            {{ t('CAPTAIN.PLAYGROUND.SETUP.TITLE') }}
          </h3>
          <p class="mt-1 text-sm text-n-slate-11">
            {{ t('CAPTAIN.PLAYGROUND.SETUP.DESCRIPTION') }}
          </p>
        </div>
        <NextButton
          ghost
          sm
          slate
          icon="i-lucide-x"
          :aria-label="t('CAPTAIN.PLAYGROUND.SETUP.CLOSE')"
          @click="isSetupOpen = false"
        />
      </div>
      <PlaygroundTestSetup
        :key="setupInstanceKey"
        :session="session"
        class="min-h-0 flex-1"
      />
      <div class="border-t border-n-weak bg-n-solid-1 p-4">
        <NextButton
          ghost
          sm
          slate
          :label="t('CAPTAIN.PLAYGROUND.SETUP.RESET')"
          icon="i-lucide-refresh-cw"
          :disabled="session.isInitializing"
          :is-loading="session.isInitializing"
          @click="resetTestSetup"
        />
      </div>
    </aside>

    <SidePanel
      v-if="isV2 && isBelowXL"
      ref="setupPanelRef"
      width="lg"
      :title="t('CAPTAIN.PLAYGROUND.SETUP.TITLE')"
      :description="t('CAPTAIN.PLAYGROUND.SETUP.DESCRIPTION')"
    >
      <PlaygroundTestSetup :key="setupInstanceKey" :session="session" />
      <template #footer>
        <NextButton
          ghost
          sm
          slate
          :label="t('CAPTAIN.PLAYGROUND.SETUP.RESET')"
          icon="i-lucide-refresh-cw"
          :disabled="session.isInitializing"
          :is-loading="session.isInitializing"
          @click="resetTestSetup"
        />
      </template>
    </SidePanel>
  </div>
</template>
