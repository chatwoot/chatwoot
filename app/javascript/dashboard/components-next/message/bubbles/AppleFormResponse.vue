<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMessageContext } from '../provider.js';
import BaseBubble from './Base.vue';

const { message, contentAttributes } = useMessageContext();
const { t } = useI18n();

// Reactive state for expanding/collapsing large forms
const showAll = ref(false);

// Extract form response data from content_attributes
const formResponse = computed(
  () => contentAttributes.value?.form_response || {}
);
const selections = computed(() => formResponse.value?.selections || []);
const formTitle = computed(() => {
  // Try to get title from various sources
  if (contentAttributes.value?.form_response?.title) {
    return contentAttributes.value.form_response.title;
  }
  // Parse from message content if it follows "FormTitle - Response:" pattern
  const content = message.value?.content || '';
  const match = content.match(/^(.+?) - Response:/);
  return match
    ? match[1]
    : t('CONVERSATION.APPLE_FORM_RESPONSE.DEFAULT_FORM_TITLE');
});

const submittedAt = computed(() => {
  const timestamp = formResponse.value?.submitted_at;
  if (timestamp) {
    return new Date(timestamp).toLocaleString();
  }
  return new Date(message.value?.created_at).toLocaleString();
});

// Format the form responses for display
const formattedResponses = computed(() => {
  if (!selections.value || selections.value.length === 0) {
    return [];
  }

  return selections.value
    .map(selection => ({
      question:
        selection.title ||
        selection.subtitle ||
        selection.pageIdentifier ||
        t('CONVERSATION.APPLE_FORM_RESPONSE.DEFAULT_QUESTION'),
      answers: (selection.items || [])
        .map(item => item.title || item.value)
        .filter(Boolean),
      hasAnswers: (selection.items || []).length > 0,
    }))
    .filter(response => response.hasAnswers);
});

const hasResponses = computed(() => formattedResponses.value.length > 0);

// Show limited responses when showAll is false
const displayedResponses = computed(() => {
  if (showAll.value || formattedResponses.value.length <= 3) {
    return formattedResponses.value;
  }
  return formattedResponses.value.slice(0, 3);
});
</script>

<template>
  <BaseBubble>
    <div class="apple-form-response max-w-md">
      <!-- Form Header -->
      <div
        class="mb-4 p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800"
      >
        <div class="flex items-center gap-2 mb-2">
          <div
            class="w-6 h-6 bg-blue-500 rounded flex items-center justify-center"
          >
            <svg
              class="w-4 h-4 text-white"
              fill="currentColor"
              viewBox="0 0 20 20"
            >
              <path d="M9 2a1 1 0 000 2h2a1 1 0 100-2H9z" />
              <path
                fill-rule="evenodd"
                d="M4 5a2 2 0 012-2v1a1 1 0 001 1h1a1 1 0 001-1V3a2 2 0 012 0v1a1 1 0 001 1h1a1 1 0 001-1V3a2 2 0 012 2v11a2 2 0 01-2 2H6a2 2 0 01-2-2V5zm3 4a1 1 0 000 2h.01a1 1 0 100-2H7zm3 0a1 1 0 000 2h3a1 1 0 100-2h-3zm-3 4a1 1 0 100 2h.01a1 1 0 100-2H7zm3 0a1 1 0 100 2h3a1 1 0 100-2h-3z"
                clip-rule="evenodd"
              />
            </svg>
          </div>
          <h3 class="text-sm font-semibold text-blue-900 dark:text-blue-100">
            {{ formTitle
            }}{{ t('CONVERSATION.APPLE_FORM_RESPONSE.HEADER.SEPARATOR')
            }}{{ t('CONVERSATION.APPLE_FORM_RESPONSE.HEADER.RESPONSE_TITLE') }}
          </h3>
        </div>
        <p class="text-xs text-blue-700 dark:text-blue-300">
          {{ t('CONVERSATION.APPLE_FORM_RESPONSE.HEADER.SUBMITTED') }}
          {{ submittedAt }}
        </p>
      </div>

      <!-- Form Responses -->
      <div v-if="hasResponses" class="space-y-3">
        <div
          v-for="(response, index) in displayedResponses"
          :key="index"
          class="p-3 bg-slate-50 dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700"
        >
          <div class="mb-2">
            <label
              class="text-sm font-medium text-slate-700 dark:text-slate-300"
            >
              {{ response.question }}
            </label>
          </div>
          <div class="space-y-1">
            <div
              v-for="(answer, answerIndex) in response.answers"
              :key="answerIndex"
              class="inline-block px-2 py-1 mr-2 mb-1 text-sm bg-white dark:bg-slate-700 border border-slate-300 dark:border-slate-600 rounded-md text-slate-800 dark:text-slate-200"
            >
              {{ answer }}
            </div>
          </div>
        </div>
      </div>

      <!-- No Responses Case -->
      <div
        v-else
        class="p-3 bg-slate-50 dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700 text-center"
      >
        <p class="text-sm text-slate-600 dark:text-slate-400">
          {{ t('CONVERSATION.APPLE_FORM_RESPONSE.NO_RESPONSES') }}
        </p>
      </div>

      <!-- Expand/Collapse for Large Forms -->
      <div v-if="formattedResponses.length > 3" class="mt-3 text-center">
        <button
          class="text-xs text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-200 transition-colors"
          @click="showAll = !showAll"
        >
          {{
            showAll
              ? t('CONVERSATION.APPLE_FORM_RESPONSE.SHOW_LESS')
              : t('CONVERSATION.APPLE_FORM_RESPONSE.SHOW_ALL', {
                  count: formattedResponses.length,
                })
          }}
        </button>
      </div>
    </div>
  </BaseBubble>
</template>

<style scoped>
.apple-form-response {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}
</style>
