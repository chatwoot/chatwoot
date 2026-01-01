<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import SettingsSection from 'dashboard/components/SettingsSection.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import AlooAssistantAPI from 'dashboard/api/aloo/assistant';

const props = defineProps({
  assistantId: {
    type: [String, Number],
    required: true,
  },
});

const { t } = useI18n();

const userMessage = ref('');
const conversationHistory = ref([]);
const isLoading = ref(false);
const error = ref(null);
const lastMetrics = ref(null);

const formattedHistory = computed(() => {
  return conversationHistory.value
    .map(
      msg => `${msg.role === 'user' ? 'Customer' : 'Assistant'}: ${msg.content}`
    )
    .join('\n\n');
});

const sendMessage = async () => {
  if (!userMessage.value.trim() || isLoading.value) return;

  const message = userMessage.value.trim();
  userMessage.value = '';
  error.value = null;

  // Add user message to history
  conversationHistory.value.push({
    role: 'user',
    content: message,
  });

  isLoading.value = true;

  try {
    const response = await AlooAssistantAPI.playground(
      props.assistantId,
      message,
      formattedHistory.value
    );

    const data = response.data;

    if (data.success !== false) {
      // Add assistant response to history
      conversationHistory.value.push({
        role: 'assistant',
        content: data.response,
        metrics: {
          inputTokens: data.input_tokens,
          outputTokens: data.output_tokens,
          totalTokens: data.total_tokens,
          durationMs: data.duration_ms,
          toolCalls: data.tool_calls,
        },
      });
      lastMetrics.value = {
        inputTokens: data.input_tokens,
        outputTokens: data.output_tokens,
        totalTokens: data.total_tokens,
        durationMs: data.duration_ms,
        toolCalls: data.tool_calls,
      };
    } else {
      error.value = data.error || t('ALOO.PLAYGROUND.ERROR_GENERIC');
    }
  } catch (err) {
    error.value =
      err.response?.data?.error || t('ALOO.PLAYGROUND.ERROR_GENERIC');
    // Remove the user message if the request failed
    conversationHistory.value.pop();
  } finally {
    isLoading.value = false;
  }
};

const clearConversation = () => {
  conversationHistory.value = [];
  lastMetrics.value = null;
  error.value = null;
};

const handleKeydown = event => {
  if (event.key === 'Enter' && !event.shiftKey) {
    event.preventDefault();
    sendMessage();
  }
};
</script>

<template>
  <div>
    <SettingsSection
      :title="$t('ALOO.PLAYGROUND.TITLE')"
      :sub-title="$t('ALOO.PLAYGROUND.DESCRIPTION')"
    >
      <!-- Conversation Display -->
      <div
        class="min-h-80 max-h-96 overflow-y-auto mb-4 p-4 border border-slate-200 dark:border-slate-700 rounded-lg bg-slate-50 dark:bg-slate-800"
      >
        <div
          v-if="conversationHistory.length === 0"
          class="text-center text-slate-500 py-8"
        >
          {{ $t('ALOO.PLAYGROUND.EMPTY_STATE') }}
        </div>

        <div
          v-for="(msg, index) in conversationHistory"
          :key="index"
          class="mb-4"
        >
          <!-- User Message -->
          <div v-if="msg.role === 'user'" class="flex justify-end">
            <div
              class="max-w-3/4 bg-woot-500 text-white px-4 py-2 rounded-lg rounded-br-sm"
            >
              {{ msg.content }}
            </div>
          </div>

          <!-- Assistant Message -->
          <div v-else class="flex justify-start">
            <div class="max-w-3/4">
              <div
                class="bg-white dark:bg-slate-700 px-4 py-2 rounded-lg rounded-bl-sm border border-slate-200 dark:border-slate-600"
              >
                <div class="whitespace-pre-wrap">{{ msg.content }}</div>
              </div>
              <!-- Metrics Badge -->
              <div
                v-if="msg.metrics"
                class="mt-1 flex gap-2 text-xs text-slate-500"
              >
                <span>
                  {{ msg.metrics.totalTokens }}
                  {{ $t('ALOO.PLAYGROUND.METRICS.TOKENS_UNIT') }}
                </span>
                <span class="text-slate-300">·</span>
                <span>
                  {{ msg.metrics.durationMs
                  }}{{ $t('ALOO.PLAYGROUND.METRICS.MS_UNIT') }}
                </span>
                <template v-if="msg.metrics.toolCalls?.length">
                  <span class="text-slate-300">·</span>
                  <span>
                    {{ $t('ALOO.PLAYGROUND.METRICS.TOOLS_LABEL') }}:
                    {{ msg.metrics.toolCalls.map(t => t.name).join(', ') }}
                  </span>
                </template>
              </div>
            </div>
          </div>
        </div>

        <!-- Loading Indicator -->
        <div v-if="isLoading" class="flex justify-start">
          <div
            class="bg-white dark:bg-slate-700 px-4 py-2 rounded-lg border border-slate-200 dark:border-slate-600"
          >
            <div class="flex items-center gap-2">
              <span class="animate-pulse">{{
                $t('ALOO.PLAYGROUND.THINKING')
              }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Error Display -->
      <div
        v-if="error"
        class="mb-4 p-3 bg-ruby-50 dark:bg-ruby-900/20 text-ruby-700 dark:text-ruby-300 rounded-lg"
      >
        {{ error }}
      </div>

      <!-- Input Area -->
      <div class="flex gap-2">
        <textarea
          v-model="userMessage"
          :placeholder="$t('ALOO.PLAYGROUND.INPUT_PLACEHOLDER')"
          :disabled="isLoading"
          rows="2"
          class="flex-1 resize-none"
          @keydown="handleKeydown"
        />
        <div class="flex flex-col gap-2">
          <Button
            :is-loading="isLoading"
            :disabled="!userMessage.trim()"
            @click="sendMessage"
          >
            {{ $t('ALOO.PLAYGROUND.SEND') }}
          </Button>
          <Button
            variant="hollow"
            :disabled="conversationHistory.length === 0"
            @click="clearConversation"
          >
            {{ $t('ALOO.PLAYGROUND.CLEAR') }}
          </Button>
        </div>
      </div>

      <!-- Metrics Summary -->
      <div
        v-if="lastMetrics"
        class="mt-4 p-3 bg-slate-100 dark:bg-slate-700 rounded-lg"
      >
        <div class="text-sm font-medium mb-2">
          {{ $t('ALOO.PLAYGROUND.LAST_RESPONSE') }}
        </div>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-2 text-sm">
          <div>
            <span class="text-slate-500">
              {{ $t('ALOO.PLAYGROUND.METRICS.INPUT_TOKENS') }}
            </span>
            <span class="ml-1 font-medium">{{
              lastMetrics.inputTokens || 0
            }}</span>
          </div>
          <div>
            <span class="text-slate-500">
              {{ $t('ALOO.PLAYGROUND.METRICS.OUTPUT_TOKENS') }}
            </span>
            <span class="ml-1 font-medium">{{
              lastMetrics.outputTokens || 0
            }}</span>
          </div>
          <div>
            <span class="text-slate-500">
              {{ $t('ALOO.PLAYGROUND.METRICS.TOTAL_TOKENS') }}
            </span>
            <span class="ml-1 font-medium">{{
              lastMetrics.totalTokens || 0
            }}</span>
          </div>
          <div>
            <span class="text-slate-500">
              {{ $t('ALOO.PLAYGROUND.METRICS.DURATION') }}
            </span>
            <span class="ml-1 font-medium">
              {{ lastMetrics.durationMs || 0
              }}{{ $t('ALOO.PLAYGROUND.METRICS.MS_UNIT') }}
            </span>
          </div>
        </div>
      </div>
    </SettingsSection>
  </div>
</template>
