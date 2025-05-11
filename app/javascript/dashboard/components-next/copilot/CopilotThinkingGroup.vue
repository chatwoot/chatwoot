<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from '../icon/Icon.vue';
import CopilotThinkingBlock from 'dashboard/components/copilot/CopilotThinkingBlock.vue';

defineProps({ messages: { type: Array, required: true } });
const { t } = useI18n();
const isExpanded = ref(false);
</script>

<template>
  <div class="flex flex-col gap-2">
    <button
      class="flex items-center gap-2 text-xs text-n-slate-10 hover:text-n-slate-11"
      @click="isExpanded = !isExpanded"
    >
      <Icon
        :icon="isExpanded ? 'i-lucide-chevron-down' : 'i-lucide-chevron-right'"
        class="w-4 h-4"
      />
      {{ t('CAPTAIN.COPILOT.SHOW_THINKING') }}
    </button>
    <div v-if="isExpanded" class="space-y-4">
      <CopilotThinkingBlock
        v-for="message in messages"
        :key="message.id"
        :content="message.content"
        :reasoning="message.reasoning"
      />
    </div>
  </div>
</template>
