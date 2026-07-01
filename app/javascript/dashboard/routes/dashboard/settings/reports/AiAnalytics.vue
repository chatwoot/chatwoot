<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import AiAnalyticsAPI from 'dashboard/api/aiAnalytics';
import Button from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const query = ref('');
const conversation = ref([
  {
    role: 'assistant',
    content: t('AI_ANALYTICS.WELCOME'),
  },
]);
const isProcessing = ref(false);

const submitQuery = async () => {
  if (!query.value.trim() || isProcessing.value) return;

  const userText = query.value.trim();
  conversation.value.push({ role: 'user', content: userText });
  query.value = '';
  isProcessing.value = true;

  try {
    const response = await AiAnalyticsAPI.query(userText);
    conversation.value.push({
      role: 'assistant',
      content: response.data.response,
    });
  } catch (error) {
    useAlert(t('AI_ANALYTICS.CONNECTION_ERROR'));
    conversation.value.push({
      role: 'assistant',
      content: t('AI_ANALYTICS.ERROR'),
    });
  } finally {
    isProcessing.value = false;
  }
};
</script>

<template>
  <div class="flex flex-col h-full bg-slate-50 dark:bg-slate-900 p-6">
    <div class="mb-4">
      <h2 class="text-2xl font-semibold text-slate-900 dark:text-white">
        {{ $t('AI_ANALYTICS.HEADER') }}
      </h2>
      <p class="text-slate-600 dark:text-slate-400">
        {{ $t('AI_ANALYTICS.DESCRIPTION') }}
      </p>
    </div>

    <div
      class="flex flex-col flex-1 bg-white border rounded-lg shadow-sm overflow-hidden dark:bg-slate-800 dark:border-slate-700"
    >
      <div
        class="flex-1 p-4 overflow-y-auto bg-slate-50/50 dark:bg-slate-900/50 space-y-4"
      >
        <div
          v-for="(message, index) in conversation"
          :key="index"
          class="flex w-full"
          :class="message.role === 'user' ? 'justify-end' : 'justify-start'"
        >
          <div
            class="max-w-[75%] p-3 rounded-xl whitespace-pre-wrap"
            :class="
              message.role === 'user'
                ? 'bg-woot-500 text-white rounded-br-none'
                : 'bg-white dark:bg-slate-800 border dark:border-slate-700 rounded-bl-none text-slate-800 dark:text-slate-200'
            "
          >
            {{ message.content }}
          </div>
        </div>
        <div v-if="isProcessing" class="flex justify-start">
          <div
            class="bg-white dark:bg-slate-800 border dark:border-slate-700 p-3 rounded-xl rounded-bl-none text-slate-500 flex gap-2"
          >
            <span class="animate-bounce">...</span>
          </div>
        </div>
      </div>

      <div
        class="p-4 bg-white border-t dark:bg-slate-800 dark:border-slate-700"
      >
        <form class="flex gap-2" @submit.prevent="submitQuery">
          <input
            v-model="query"
            type="text"
            :placeholder="$t('AI_ANALYTICS.PLACEHOLDER')"
            class="flex-1 px-4 py-2 border rounded-lg dark:bg-slate-900 dark:border-slate-600 dark:text-white focus:outline-none focus:ring-2 focus:ring-woot-500"
            :disabled="isProcessing"
          />
          <Button
            type="submit"
            :label="$t('AI_ANALYTICS.ASK')"
            icon="sparkle"
            :is-loading="isProcessing"
            :disabled="!query.trim()"
          />
        </form>
      </div>
    </div>
  </div>
</template>
