<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import Icon from '../icon/Icon.vue';

const props = defineProps({
  hasAssistant: {
    type: Boolean,
    default: false,
  },
  canSuggestReply: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['useSuggestion']);
const { t } = useI18n();
const route = useRoute();

const routePromptMap = {
  conversations: [
    {
      label: 'CAPTAIN.COPILOT.PROMPTS.SUMMARIZE.LABEL',
      prompt: 'CAPTAIN.COPILOT.PROMPTS.SUMMARIZE.CONTENT',
    },
    {
      label: 'CAPTAIN.COPILOT.PROMPTS.SUGGEST.LABEL',
      prompt: 'CAPTAIN.COPILOT.PROMPTS.SUGGEST.CONTENT',
      requestType: 'reply_suggestion',
    },
    {
      label: 'CAPTAIN.COPILOT.PROMPTS.RATE.LABEL',
      prompt: 'CAPTAIN.COPILOT.PROMPTS.RATE.CONTENT',
    },
  ],
  dashboard: [
    {
      label: 'CAPTAIN.COPILOT.PROMPTS.HIGH_PRIORITY.LABEL',
      prompt: 'CAPTAIN.COPILOT.PROMPTS.HIGH_PRIORITY.CONTENT',
    },
    {
      label: 'CAPTAIN.COPILOT.PROMPTS.LIST_CONTACTS.LABEL',
      prompt: 'CAPTAIN.COPILOT.PROMPTS.LIST_CONTACTS.CONTENT',
    },
  ],
};

const getCurrentRoute = () => {
  const path = route.path;
  if (path.includes('/conversations')) return 'conversations';
  if (path.includes('/dashboard')) return 'dashboard';
  return 'dashboard';
};

const promptOptions = computed(() => {
  const currentRoute = getCurrentRoute();
  const prompts = routePromptMap[currentRoute] || routePromptMap.conversations;

  return prompts.filter(
    prompt => prompt.requestType !== 'reply_suggestion' || props.canSuggestReply
  );
});

const handleSuggestion = opt => {
  const message = t(opt.prompt);
  emit(
    'useSuggestion',
    opt.requestType ? { message, requestType: opt.requestType } : message
  );
};
</script>

<template>
  <div class="flex-1 flex flex-col gap-7 px-1 pt-7">
    <div class="space-y-3">
      <span
        class="flex size-11 items-center justify-center rounded-xl bg-n-blue-3 text-n-blue-11"
      >
        <Icon icon="i-woot-captain" class="text-2xl" />
      </span>
      <div>
        <h3 class="text-base font-medium text-n-slate-12">
          {{ t('CAPTAIN.COPILOT.PANEL_TITLE') }}
        </h3>
        <p v-if="hasAssistant" class="mt-1 text-sm leading-5 text-n-slate-11">
          {{ t('CAPTAIN.COPILOT.EMPTY_ASSISTANT') }}
        </p>
      </div>
    </div>
    <div v-if="!hasAssistant" class="w-full space-y-2">
      <p class="text-sm leading-6 text-n-slate-11">
        {{ t('CAPTAIN.ASSISTANTS.NO_ASSISTANTS_AVAILABLE') }}
      </p>
      <router-link
        :to="{
          name: 'captain_assistants_create_index',
          params: { accountId: route.params.accountId },
        }"
        class="text-n-slate-11 underline hover:text-n-slate-12"
      >
        {{ t('CAPTAIN.ASSISTANTS.ADD_NEW') }}
      </router-link>
    </div>
    <div v-else class="w-full space-y-2">
      <span class="block text-xs font-medium text-n-slate-10">
        {{ $t('CAPTAIN.COPILOT.TRY_THESE_PROMPTS') }}
      </span>
      <div class="space-y-1">
        <button
          v-for="prompt in promptOptions"
          :key="prompt.label"
          class="flex w-full items-center justify-between gap-3 rounded-lg border border-n-weak bg-n-surface-2 px-3 py-2.5 text-left text-sm text-n-slate-12 transition-colors hover:bg-n-alpha-2"
          @click="handleSuggestion(prompt)"
        >
          <span>{{ t(prompt.label) }}</span>
          <Icon
            icon="i-lucide-arrow-up-right"
            class="shrink-0 text-n-slate-10"
          />
        </button>
      </div>
    </div>
  </div>
</template>
