<script setup>
import { ref, nextTick, onMounted, onUnmounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useSetupWizard } from '../../composables/useSetupWizard';
import WizardMessage from './WizardMessage.vue';
import WizardProgressBar from './WizardProgressBar.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const emit = defineEmits(['created', 'skip']);

const { t } = useI18n();

const {
  messages,
  isStreaming,
  isComplete,
  wizardResult,
  isCreatingAgent,
  currentStepIndex,
  progressPercent,
  stepLabels,
  sendWizardMessage,
  createAgentFromWizard,
  startWizard,
  disconnect,
} = useSetupWizard();

const userInput = ref('');
const chatContainer = ref(null);
const hasInitError = ref(false);
// Track the id of the auto-sent initial message so we can hide it
const initialMessageId = ref(null);

const scrollToBottom = async () => {
  await nextTick();
  if (chatContainer.value) {
    chatContainer.value.scrollTop = chatContainer.value.scrollHeight;
  }
};

const handleSend = async () => {
  const content = userInput.value.trim();
  if (!content || isStreaming.value) return;

  userInput.value = '';
  await sendWizardMessage(content);
  scrollToBottom();
};

const handleKeydown = event => {
  if (event.key === 'Enter' && !event.shiftKey) {
    event.preventDefault();
    handleSend();
  }
};

const handleCreate = async () => {
  const agent = await createAgentFromWizard();
  if (agent) {
    emit('created', agent);
  }
};

const sendInitialGreeting = async () => {
  hasInitError.value = false;
  const greeting = t('AI_AGENTS.WIZARD.INITIAL_GREETING');
  await sendWizardMessage(greeting);
  scrollToBottom();

  // Mark the initial user message as hidden
  const firstUserMsg = messages.value.find(m => m.role === 'user');
  if (firstUserMsg) {
    initialMessageId.value = firstUserMsg.id;
  }

  // Check if the last assistant message has an error
  const lastAssistant = messages.value
    .slice()
    .reverse()
    .find(m => m.role === 'assistant');
  if (lastAssistant?.error) {
    hasInitError.value = true;
  }
};

const handleRetry = () => {
  // Remove the failed assistant message and user message, then retry
  const lastTwo = messages.value.slice(-2);
  if (lastTwo.length === 2 && lastTwo[1]?.error) {
    messages.value.splice(-2, 2);
  }
  sendInitialGreeting();
};

/**
 * Visible messages: exclude system + hide the auto-sent initial user message.
 */
const isVisible = msg => {
  if (msg.role === 'system') return false;
  if (msg.id === initialMessageId.value) return false;
  return true;
};

onMounted(() => {
  startWizard();
  sendInitialGreeting();
});

onUnmounted(() => {
  disconnect();
});
</script>

<template>
  <div class="flex flex-col h-full max-h-[75vh]">
    <!-- Header -->
    <div
      class="flex flex-col gap-4 px-6 py-4 border-b border-n-weak bg-n-solid-1"
    >
      <div class="flex items-center justify-between">
        <p class="text-sm text-n-slate-10">
          {{ t('AI_AGENTS.WIZARD.SUBTITLE') }}
        </p>
        <button
          type="button"
          class="text-xs text-n-slate-10 hover:text-n-blue-11 transition-colors underline decoration-dotted underline-offset-2"
          @click="$emit('skip')"
        >
          {{ t('AI_AGENTS.WIZARD.SKIP') }}
        </button>
      </div>
      <WizardProgressBar
        :steps="stepLabels"
        :current-index="currentStepIndex"
        :progress-percent="progressPercent"
      />
    </div>

    <!-- Chat Messages -->
    <div
      ref="chatContainer"
      class="flex-1 overflow-y-auto px-6 py-5 flex flex-col gap-4 bg-n-background"
    >
      <template v-for="msg in messages" :key="msg.id">
        <WizardMessage
          v-if="isVisible(msg)"
          :role="msg.role"
          :content="msg.content"
          :is-streaming="msg.streaming"
          :error="msg.error"
        />
      </template>
    </div>

    <!-- Wizard Complete: Review & Create -->
    <div
      v-if="isComplete"
      class="px-6 py-5 border-t border-n-weak bg-n-solid-1"
    >
      <div class="flex flex-col gap-3">
        <div class="flex items-center gap-2">
          <span class="i-lucide-check-circle size-5 text-n-green-11" />
          <span class="text-sm font-semibold text-n-slate-12">
            {{ t('AI_AGENTS.WIZARD.REVIEW_TITLE') }}
          </span>
        </div>
        <p class="text-xs text-n-slate-10">
          {{ t('AI_AGENTS.WIZARD.REVIEW_DESCRIPTION') }}
        </p>

        <!-- Preview of generated config -->
        <div
          v-if="wizardResult"
          class="rounded-xl border border-n-weak bg-n-solid-2 p-4 text-xs space-y-2"
        >
          <div class="flex items-center gap-2">
            <span class="text-n-slate-10">
              {{ t('AI_AGENTS.WIZARD.REVIEW_NAME') }}
            </span>
            <span class="text-n-slate-12 font-medium">
              {{ wizardResult.name }}
            </span>
          </div>
          <div v-if="wizardResult.description" class="flex items-center gap-2">
            <span class="text-n-slate-10">
              {{ t('AI_AGENTS.WIZARD.REVIEW_DESCRIPTION_LABEL') }}
            </span>
            <span class="text-n-slate-12">
              {{ wizardResult.description }}
            </span>
          </div>
          <div class="flex items-center gap-2">
            <span class="text-n-slate-10">
              {{ t('AI_AGENTS.WIZARD.REVIEW_SECTIONS_FILLED') }}
            </span>
            <span class="text-n-slate-12 font-medium">
              {{
                t('AI_AGENTS.WIZARD.REVIEW_SECTIONS_COUNT', {
                  count: Object.values(
                    wizardResult.prompt_sections || {}
                  ).filter(v => v).length,
                })
              }}
            </span>
          </div>
        </div>

        <Button
          :label="t('AI_AGENTS.WIZARD.CREATE_AGENT')"
          :is-loading="isCreatingAgent"
          :disabled="isCreatingAgent"
          @click="handleCreate"
        />
      </div>
    </div>

    <!-- Input Area -->
    <div v-else class="px-6 py-4 border-t border-n-weak bg-n-solid-1">
      <!-- Error recovery -->
      <div
        v-if="hasInitError"
        class="flex items-center justify-between gap-3 mb-3 px-3 py-2.5 rounded-xl bg-n-ruby-2 border border-n-ruby-7"
      >
        <div class="flex items-center gap-2">
          <span class="i-lucide-alert-triangle size-4 text-n-ruby-9" />
          <span class="text-xs text-n-ruby-11">
            {{ t('AI_AGENTS.WIZARD.CONNECTION_ERROR') }}
          </span>
        </div>
        <button
          type="button"
          class="flex items-center gap-1 text-xs font-medium text-n-ruby-11 hover:text-n-ruby-12 shrink-0"
          @click="handleRetry"
        >
          <span class="i-lucide-refresh-cw size-3" />
          {{ t('AI_AGENTS.WIZARD.RETRY') }}
        </button>
      </div>

      <!-- Chat input with inline send button -->
      <div
        class="flex items-end gap-2 rounded-xl border border-n-weak bg-n-solid-2 px-3 py-2 focus-within:ring-2 focus-within:ring-n-blue-7 focus-within:border-transparent transition-all"
      >
        <textarea
          v-model="userInput"
          :placeholder="t('AI_AGENTS.WIZARD.INPUT_PLACEHOLDER')"
          rows="1"
          class="flex-1 py-1 text-sm bg-transparent text-n-slate-12 placeholder:text-n-slate-9 focus:outline-none resize-none leading-relaxed"
          :disabled="isStreaming"
          @keydown="handleKeydown"
        />
        <button
          type="button"
          class="flex items-center justify-center shrink-0 size-8 rounded-lg transition-all duration-200"
          :class="
            isStreaming || !userInput.trim()
              ? 'bg-n-solid-3 text-n-slate-9 cursor-not-allowed'
              : 'bg-n-blue-9 text-white hover:bg-n-blue-10 shadow-sm'
          "
          :disabled="isStreaming || !userInput.trim()"
          @click="handleSend"
        >
          <span class="i-lucide-arrow-up size-4" />
        </button>
      </div>
    </div>
  </div>
</template>
