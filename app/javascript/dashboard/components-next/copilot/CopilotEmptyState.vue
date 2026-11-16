<script setup>
import { useRoute } from 'vue-router';
import { useCopilotPrompts } from 'dashboard/composables/useCopilotPrompts';
import Icon from '../icon/Icon.vue';
import CopilotPromptPills from './CopilotPromptPills.vue';

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
const route = useRoute();
const { prompts, selectPrompt } = useCopilotPrompts({
  isWorkflowsEnabled: () => props.isWorkflowsEnabled,
  canSuggestReply: () => props.canSuggestReply,
});

const handleSuggestion = key => {
  emit('useSuggestion', selectPrompt(key));
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
    <CopilotPromptPills
      v-else-if="$slots.logo"
      :prompts="prompts"
      class="mt-auto"
      @select="handleSuggestion"
    />
    <div v-else class="w-full space-y-2">
      <span class="text-xs text-n-slate-10 block">
        {{ $t('CAPTAIN.COPILOT.TRY_THESE_PROMPTS') }}
      </span>
      <div class="space-y-1">
        <button
          v-for="prompt in prompts"
          :key="prompt.key"
          class="w-full px-3 py-2 rounded-md border border-n-weak bg-n-slate-2 text-n-slate-11 flex items-center justify-between hover:bg-n-slate-3 transition-colors"
          @click="handleSuggestion(prompt.key)"
        >
          <span>{{ prompt.label }}</span>
          <Icon icon="i-lucide-chevron-right" />
        </button>
      </div>
    </div>
  </div>
</template>
