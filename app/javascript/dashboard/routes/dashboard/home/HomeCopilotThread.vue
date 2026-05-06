<script setup>
import { computed, nextTick, onMounted, ref, watch } from 'vue';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useAccount } from 'dashboard/composables/useAccount';
import CopilotMessagesAPI from 'dashboard/api/captain/copilotMessages';
import CopilotAgentMessage from 'dashboard/components-next/copilot/CopilotAgentMessage.vue';
import CopilotAssistantMessage from 'dashboard/components-next/copilot/CopilotAssistantMessage.vue';
import CopilotThinkingGroup from 'dashboard/components-next/copilot/CopilotThinkingGroup.vue';
import CopilotLoader from 'dashboard/components-next/copilot/CopilotLoader.vue';
import CopilotInput from 'dashboard/components-next/copilot/CopilotInput.vue';
import ToggleCopilotAssistant from 'dashboard/components-next/copilot/ToggleCopilotAssistant.vue';

const props = defineProps({
  threadId: {
    type: [String, Number],
    required: true,
  },
});

const store = useStore();
const router = useRouter();
const { uiSettings, updateUISettings } = useUISettings();
const { accountScopedRoute } = useAccount();

const assistants = useMapGetter('captainAssistants/getRecords');

const messages = computed(() =>
  store.getters['copilotMessages/getMessagesByThreadId'](props.threadId)
);

const activeAssistant = computed(() => {
  const preferredId = uiSettings.value.preferred_captain_assistant_id;
  if (preferredId) {
    const found = assistants.value.find(a => a.id === preferredId);
    if (found) return found;
  }
  return assistants.value[0];
});

const setAssistant = async assistant => {
  await updateUISettings({
    preferred_captain_assistant_id: assistant.id,
  });
};

const sendMessage = async message => {
  try {
    await store.dispatch('copilotMessages/create', {
      assistant_id: activeAssistant.value?.id,
      threadId: props.threadId,
      message,
    });
  } catch (error) {
    useAlert(error.message);
  }
};

const goHome = () => {
  router.push(accountScopedRoute('home_dashboard'));
};

const groupedMessages = computed(() => {
  const result = [];
  let thinkingGroup = [];
  messages.value.forEach(message => {
    if (message.message_type === 'assistant_thinking') {
      thinkingGroup.push(message);
    } else {
      if (thinkingGroup.length) {
        result.push({
          id: thinkingGroup[0].id,
          message_type: 'thinking_group',
          messages: thinkingGroup,
        });
        thinkingGroup = [];
      }
      result.push(message);
    }
  });
  if (thinkingGroup.length) {
    result.push({
      id: thinkingGroup[0].id,
      message_type: 'thinking_group',
      messages: thinkingGroup,
    });
  }
  return result;
});

const isLastMessageFromAssistant = computed(() => {
  const last = groupedMessages.value[groupedMessages.value.length - 1];
  return last?.message_type === 'assistant';
});

const chatContainer = ref(null);
const scrollToBottom = async () => {
  await nextTick();
  if (chatContainer.value) {
    chatContainer.value.scrollTop = chatContainer.value.scrollHeight;
  }
};

watch(() => messages.value, scrollToBottom, { deep: true });

onMounted(async () => {
  store.dispatch('captainAssistants/get');
  try {
    const { data } = await CopilotMessagesAPI.get(props.threadId);
    const payload = data?.payload || [];
    payload.forEach(message => {
      store.dispatch('copilotMessages/upsert', message);
    });
    scrollToBottom();
  } catch {
    // best-effort fetch; rely on websocket if API errors
  }
});
</script>

<template>
  <section class="flex flex-col w-full h-full bg-n-surface-1 text-n-slate-12">
    <div
      class="flex items-center gap-2 px-6 py-3 border-b border-n-weak flex-shrink-0"
    >
      <button
        type="button"
        class="inline-flex items-center gap-1.5 h-8 px-2.5 rounded-md text-[13px] font-medium text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-2 transition-colors bg-transparent border-0 cursor-pointer"
        @click="goHome"
      >
        <span class="i-lucide-chevron-left size-4" />
        {{ $t('HOME_DASHBOARD_PAGE.COPILOT_THREAD.BACK') }}
      </button>
    </div>
    <div
      ref="chatContainer"
      class="flex-1 min-h-0 w-full overflow-y-auto text-sm leading-6 tracking-tight"
    >
      <div class="w-full max-w-[820px] mx-auto px-6 py-6">
        <div
          v-if="groupedMessages.length"
          class="space-y-6 flex flex-col w-full"
        >
          <template v-for="(item, index) in groupedMessages" :key="item.id">
            <CopilotAgentMessage
              v-if="item.message_type === 'user'"
              :message="item.message"
            />
            <CopilotAssistantMessage
              v-else-if="item.message_type === 'assistant'"
              :message="item.message"
              :is-last-message="index === groupedMessages.length - 1"
              conversation-inbox-type=""
            />
            <CopilotThinkingGroup
              v-else
              :messages="item.messages"
              :default-collapsed="isLastMessageFromAssistant"
            />
          </template>
          <CopilotLoader v-if="!isLastMessageFromAssistant" />
        </div>
        <div
          v-else
          class="flex items-center justify-center h-full text-sm text-n-slate-10"
        >
          {{ $t('HOME_DASHBOARD_PAGE.TOP_CONVERSATIONS.LOADING') }}
        </div>
      </div>
    </div>
    <div class="w-full flex-shrink-0">
      <div class="w-full max-w-[820px] mx-auto px-6 pt-px pb-4">
        <div class="flex items-center justify-between gap-2 mb-1">
          <ToggleCopilotAssistant
            v-if="assistants.length > 1"
            :assistants="assistants"
            :active-assistant="activeAssistant || {}"
            @set-assistant="setAssistant"
          />
          <div v-else />
        </div>
        <CopilotInput
          v-if="assistants.length"
          class="w-full"
          @send="sendMessage"
        />
      </div>
    </div>
  </section>
</template>
