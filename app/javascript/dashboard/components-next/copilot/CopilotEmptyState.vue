<script setup>
import { useI18n } from 'vue-i18n';
import Icon from '../icon/Icon.vue';
const emit = defineEmits(['useSuggestion']);

const { t } = useI18n();

const promptOptions = [
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
];

const handleSuggestion = opt => {
  emit('useSuggestion', t(opt.prompt));
};
</script>

<template>
  <div class="flex-1 flex flex-col gap-6 px-2">
    <div class="flex flex-col space-y-4 py-4">
      <Icon icon="i-woot-captain" class="text-n-slate-9 text-4xl" />
      <div class="space-y-1">
        <h3 class="text-base font-medium text-n-slate-12 leading-8">
          {{ $t('CAPTAIN.COPILOT.PANEL_TITLE') }}
        </h3>
        <p class="text-sm text-n-slate-11 leading-6">
          {{ $t('CAPTAIN.COPILOT.KICK_OFF_MESSAGE') }}
        </p>
      </div>
    </div>
    <div class="w-full space-y-2">
      <span class="text-xs text-n-slate-10 block">
        {{ $t('CAPTAIN.COPILOT.TRY_THESE_PROMPTS') }}
      </span>
      <div class="space-y-1">
        <button
          v-for="prompt in promptOptions"
          :key="prompt.label"
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
