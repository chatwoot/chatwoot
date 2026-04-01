<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import Icon from '../icon/Icon.vue';

defineProps({
  hasAssistants: {
    type: Boolean,
    default: false,
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
  return routePromptMap[currentRoute] || routePromptMap.conversations;
});

const handleSuggestion = opt => {
  emit('useSuggestion', t(opt.prompt));
};
</script>

<template>
  <div class="flex flex-1 flex-col gap-6 px-2">
    <div
      class="flex flex-col space-y-4 rounded-xl border border-outline-variant/10 bg-surface-container-low/60 py-4 pl-4 pr-3 shadow-sm"
    >
      <Icon icon="i-woot-captain" class="text-4xl text-secondary" />
      <div class="space-y-1">
        <h3 class="text-base font-semibold leading-8 text-on-surface">
          {{ $t('CAPTAIN.COPILOT.PANEL_TITLE') }}
        </h3>
        <p class="mb-0 text-sm leading-6 text-on-surface-variant">
          {{ $t('CAPTAIN.COPILOT.KICK_OFF_MESSAGE') }}
        </p>
      </div>
    </div>
    <div
      v-if="!hasAssistants"
      class="w-full space-y-2 rounded-xl border border-outline-variant/10 bg-surface-container-low/40 p-4"
    >
      <p class="mb-0 text-sm leading-6 text-on-surface-variant">
        {{ $t('CAPTAIN.ASSISTANTS.NO_ASSISTANTS_AVAILABLE') }}
      </p>
      <router-link
        :to="{
          name: 'captain_assistants_create_index',
          params: {
            accountId: route.params.accountId,
          },
        }"
        class="text-sm font-medium text-secondary underline decoration-secondary/40 underline-offset-2 transition-colors hover:text-secondary hover:decoration-secondary"
      >
        {{ $t('CAPTAIN.ASSISTANTS.ADD_NEW') }}
      </router-link>
    </div>
    <div v-else class="w-full space-y-3">
      <span
        class="block text-xs font-semibold uppercase tracking-wider text-on-surface-variant"
      >
        {{ $t('CAPTAIN.COPILOT.TRY_THESE_PROMPTS') }}
      </span>
      <div class="space-y-2">
        <button
          v-for="prompt in promptOptions"
          :key="prompt.label"
          type="button"
          class="flex w-full items-center justify-between gap-2 rounded-lg border border-outline-variant/20 bg-surface-container-lowest px-3 py-2.5 text-left text-sm text-on-surface transition-colors hover:border-secondary/30 hover:bg-surface-container"
          @click="handleSuggestion(prompt)"
        >
          <span>{{ t(prompt.label) }}</span>
          <Icon
            icon="i-lucide-chevron-right"
            class="size-4 shrink-0 text-on-surface-variant"
          />
        </button>
      </div>
    </div>
  </div>
</template>
