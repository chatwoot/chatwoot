<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useTrack } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store';
import { COPILOT_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import Icon from '../icon/Icon.vue';
import Button from '../button/Button.vue';

const props = defineProps({
  hasAssistants: {
    type: Boolean,
    default: false,
  },
  canSuggestReply: {
    type: Boolean,
    default: true,
  },
  isWorkflowsEnabled: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['useSuggestion']);
const { t } = useI18n();
const route = useRoute();
const currentRole = useMapGetter('getCurrentRole');

const PROMPTS = {
  SUMMARIZE: {
    label: 'CAPTAIN.COPILOT.PROMPTS.SUMMARIZE.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.SUMMARIZE.CONTENT',
  },
  SUGGEST: {
    label: 'CAPTAIN.COPILOT.PROMPTS.SUGGEST.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.SUGGEST.CONTENT',
    requestType: 'reply_suggestion',
  },
  RATE: {
    label: 'CAPTAIN.COPILOT.PROMPTS.RATE.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.RATE.CONTENT',
  },
  HIGH_PRIORITY: {
    label: 'CAPTAIN.COPILOT.PROMPTS.HIGH_PRIORITY.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.HIGH_PRIORITY.CONTENT',
  },
  LIST_CONTACTS: {
    label: 'CAPTAIN.COPILOT.PROMPTS.LIST_CONTACTS.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.LIST_CONTACTS.CONTENT',
  },
  WAITING_ON_ME: {
    label: 'CAPTAIN.COPILOT.PROMPTS.WAITING_ON_ME.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.WAITING_ON_ME.CONTENT',
  },
  RECENT_CONVERSATIONS: {
    label: 'CAPTAIN.COPILOT.PROMPTS.RECENT_CONVERSATIONS.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.RECENT_CONVERSATIONS.CONTENT',
  },
  TEAM_WORKLOAD: {
    label: 'CAPTAIN.COPILOT.PROMPTS.TEAM_WORKLOAD.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.TEAM_WORKLOAD.CONTENT',
  },
  TOP_QUESTIONS: {
    label: 'CAPTAIN.COPILOT.PROMPTS.TOP_QUESTIONS.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.TOP_QUESTIONS.CONTENT',
  },
};

const routePromptMap = {
  conversations: ['SUMMARIZE', 'SUGGEST', 'RATE'],
  dashboard: ['HIGH_PRIORITY', 'LIST_CONTACTS'],
};

// Workflows answers across many conversations, so its prompts follow the person's role instead of the page. Each one
// reads only conversations the person can open, and still has an answer on a quiet account.
const rolePromptMap = {
  agent: ['WAITING_ON_ME', 'RECENT_CONVERSATIONS'],
  administrator: ['WAITING_ON_ME', 'TEAM_WORKLOAD', 'TOP_QUESTIONS'],
};

const getCurrentRoute = () => {
  const path = route.path;
  if (path.includes('/conversations')) return 'conversations';
  if (path.includes('/dashboard')) return 'dashboard';
  return 'dashboard';
};

const promptOptions = computed(() => {
  const keys = props.isWorkflowsEnabled
    ? rolePromptMap[currentRole.value] || rolePromptMap.agent
    : routePromptMap[getCurrentRoute()];

  return keys
    .map(key => ({ key, ...PROMPTS[key] }))
    .filter(
      prompt =>
        prompt.requestType !== 'reply_suggestion' || props.canSuggestReply
    );
});

const handleSuggestion = prompt => {
  useTrack(COPILOT_EVENTS.SEND_SUGGESTED, {
    prompt: prompt.key,
    role: currentRole.value,
  });
  const message = t(prompt.content);
  emit(
    'useSuggestion',
    prompt.requestType ? { message, requestType: prompt.requestType } : message
  );
};
</script>

<template>
  <div class="flex-1 self-stretch flex flex-col gap-6 px-2">
    <!-- The avatar fills the logo slot, so the title and description center under it. -->
    <div
      class="flex flex-col space-y-4 py-4"
      :class="{ 'items-center text-center': $slots.logo }"
    >
      <slot name="logo">
        <Icon icon="i-woot-captain" class="text-n-slate-9 text-4xl" />
      </slot>
      <div class="space-y-1">
        <h3 class="text-base font-medium text-n-slate-12 leading-8">
          {{ $t('CAPTAIN.COPILOT.PANEL_TITLE') }}
        </h3>
        <p class="text-sm text-n-slate-11 leading-6">
          {{ $t('CAPTAIN.COPILOT.KICK_OFF_MESSAGE') }}
        </p>
      </div>
    </div>
    <div v-if="!hasAssistants" class="w-full space-y-2">
      <p class="text-sm text-n-slate-11 leading-6">
        {{ $t('CAPTAIN.ASSISTANTS.NO_ASSISTANTS_AVAILABLE') }}
      </p>
      <router-link
        :to="{
          name: 'captain_assistants_create_index',
          params: {
            accountId: route.params.accountId,
          },
        }"
        class="text-n-slate-11 underline hover:text-n-slate-12"
      >
        {{ $t('CAPTAIN.ASSISTANTS.ADD_NEW') }}
      </router-link>
    </div>
    <!-- Next to the avatar the prompts sit above the input as pills. Without it, Copilot keeps the list. -->
    <div v-else-if="$slots.logo" class="flex flex-wrap gap-2 mt-auto">
      <Button
        v-for="prompt in promptOptions"
        :key="prompt.key"
        :label="t(prompt.label)"
        faded
        slate
        sm
        class="!rounded-full"
        @click="handleSuggestion(prompt)"
      />
    </div>
    <div v-else class="w-full space-y-2">
      <span class="text-xs text-n-slate-10 block">
        {{ $t('CAPTAIN.COPILOT.TRY_THESE_PROMPTS') }}
      </span>
      <div class="space-y-1">
        <button
          v-for="prompt in promptOptions"
          :key="prompt.key"
          class="w-full px-3 py-2 rounded-md border border-n-weak bg-n-slate-2 text-n-slate-11 flex items-center justify-between hover:bg-n-slate-3 transition-colors"
          @click="handleSuggestion(prompt)"
        >
          <span>{{ t(prompt.label) }}</span>
          <Icon icon="i-lucide-chevron-right" />
        </button>
      </div>
    </div>
  </div>
</template>
