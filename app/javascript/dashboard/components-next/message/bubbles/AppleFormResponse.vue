<script setup>
import { computed, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMessageContext } from '../provider.js';
import BaseBubble from './Base.vue';

const { message, contentAttributes } = useMessageContext();
const { t } = useI18n();

onMounted(() => {
  console.log('AppleFormResponse mounted');
  console.log(
    'contentAttributes:',
    JSON.stringify(contentAttributes.value, null, 2)
  );
  console.log('form_response:', contentAttributes.value?.form_response);
  console.log(
    'selections:',
    contentAttributes.value?.form_response?.selections
  );
  console.log('interactive_data:', contentAttributes.value?.interactive_data);
  console.log(
    'interactive_data.data:',
    contentAttributes.value?.interactive_data?.data
  );
  console.log(
    'interactive_data.data.dynamic:',
    contentAttributes.value?.interactive_data?.data?.dynamic
  );
});

// Reactive state for expanding/collapsing large forms
const showAll = ref(false);

// Extract form response data from content_attributes (handle both camelCase and snake_case)
const formResponse = computed(
  () =>
    contentAttributes.value?.formResponse ||
    contentAttributes.value?.form_response ||
    {}
);
const selections = computed(() => {
  const response =
    contentAttributes.value?.formResponse ||
    contentAttributes.value?.form_response;
  return response?.selections || [];
});
const formTitle = computed(() => {
  try {
    // Try to get title from various sources
    const response =
      contentAttributes.value?.formResponse ||
      contentAttributes.value?.form_response;
    if (response?.title) {
      return response.title;
    }
    // Parse from message content if it follows "FormTitle - Submitted" pattern
    if (message?.value?.content) {
      const content = message.value.content;
      const match = content.match(/^(.+?) - Submitted/);
      if (match) {
        return match[1];
      }
    }
    return 'Form Response';
  } catch (e) {
    console.error('Error getting form title:', e);
    return 'Form Response';
  }
});

const submittedAt = computed(() => {
  const timestamp =
    formResponse.value?.submittedAt || formResponse.value?.submitted_at;
  if (timestamp) {
    return new Date(timestamp).toLocaleString();
  }
  if (message?.value?.created_at) {
    return new Date(message.value.created_at).toLocaleString();
  }
  return new Date().toLocaleString();
});

// Check if this is an error case where IDR processing failed
const hasError = computed(() => {
  const response =
    contentAttributes.value?.formResponse ||
    contentAttributes.value?.form_response;
  const interactiveResponse =
    contentAttributes.value?.interactiveResponse ||
    contentAttributes.value?.interactive_response;
  return (
    contentAttributes.value?.idr_failed ||
    response?.error ||
    interactiveResponse?.error
  );
});

const errorMessage = computed(() => {
  const response =
    contentAttributes.value?.formResponse ||
    contentAttributes.value?.form_response;
  const interactiveResponse =
    contentAttributes.value?.interactiveResponse ||
    contentAttributes.value?.interactive_response;
  if (response?.error) {
    return response.error;
  }
  if (interactiveResponse?.user_message) {
    return interactiveResponse.user_message;
  }
  if (interactiveResponse?.error) {
    return interactiveResponse.error;
  }
  return 'Form data could not be loaded.';
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
        'Question',
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
        class="mb-3 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800"
      >
        <div class="flex items-center gap-2">
          <div
            class="w-5 h-5 bg-blue-500 rounded flex items-center justify-center flex-shrink-0"
          >
            <svg
              class="w-3 h-3 text-white"
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
          <div class="flex-1 min-w-0">
            <h3
              class="text-sm font-semibold text-blue-900 dark:text-blue-100 truncate"
            >
              {{ formTitle }}
            </h3>
            <p class="text-xs text-blue-700 dark:text-blue-300">
              {{ submittedAt }}
            </p>
          </div>
        </div>
      </div>

      <!-- Form Responses -->
      <div v-if="hasResponses && !hasError" class="space-y-2">
        <div
          v-for="(response, index) in displayedResponses"
          :key="index"
          class="p-2.5 bg-slate-50 dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700"
        >
          <label
            class="text-xs font-medium text-slate-600 dark:text-slate-400 block mb-1.5"
          >
            {{ response.question }}
          </label>
          <div class="flex flex-wrap gap-1.5">
            <div
              v-for="(answer, answerIndex) in response.answers"
              :key="answerIndex"
              class="inline-block px-2 py-1 text-sm bg-white dark:bg-slate-700 border border-slate-300 dark:border-slate-600 rounded text-slate-800 dark:text-slate-200"
            >
              {{ answer }}
            </div>
          </div>
        </div>
      </div>

      <!-- Error Case -->
      <div
        v-else-if="hasError"
        class="p-3 bg-amber-50 dark:bg-amber-900/20 rounded-lg border border-amber-200 dark:border-amber-800"
      >
        <div class="flex items-start gap-2">
          <div
            class="w-5 h-5 bg-amber-500 rounded flex items-center justify-center flex-shrink-0"
          >
            <svg
              class="w-3 h-3 text-white"
              fill="currentColor"
              viewBox="0 0 20 20"
            >
              <path
                fill-rule="evenodd"
                d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
                clip-rule="evenodd"
              />
            </svg>
          </div>
          <div>
            <p
              class="text-sm font-medium text-amber-800 dark:text-amber-200 mb-1"
            >
              Error Loading Form
            </p>
            <p class="text-xs text-amber-700 dark:text-amber-300">
              {{ errorMessage }}
            </p>
          </div>
        </div>
      </div>

      <!-- No Responses Case -->
      <div
        v-else
        class="p-2.5 bg-slate-50 dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700 text-center"
      >
        <p class="text-xs text-slate-600 dark:text-slate-400">
          No responses received
        </p>
      </div>

      <!-- Expand/Collapse for Large Forms -->
      <div v-if="formattedResponses.length > 3" class="mt-2 text-center">
        <button
          class="text-xs text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-200 transition-colors"
          @click="showAll = !showAll"
        >
          {{
            showAll ? 'Show Less' : `Show All (${formattedResponses.length})`
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
