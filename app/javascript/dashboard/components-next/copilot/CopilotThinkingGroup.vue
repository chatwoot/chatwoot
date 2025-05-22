<script setup>
import { ref, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from '../icon/Icon.vue';
import CopilotThinkingBlock from './CopilotThinkingBlock.vue';

const props = defineProps({
  messages: { type: Array, required: true },
  defaultCollapsed: { type: Boolean, default: false },
});
const { t } = useI18n();
const isExpanded = ref(!props.defaultCollapsed);

const thinkingCount = computed(() => props.messages.length);

watch(
  () => props.defaultCollapsed,
  newValue => {
    if (newValue) {
      isExpanded.value = false;
    }
  }
);
</script>

<template>
  <div class="flex flex-col gap-2">
    <button
      class="group flex items-center gap-2 text-xs text-n-slate-10 hover:text-n-slate-11 transition-colors duration-200 -ml-3"
      @click="isExpanded = !isExpanded"
    >
      <Icon
        :icon="isExpanded ? 'i-lucide-chevron-down' : 'i-lucide-chevron-right'"
        class="w-4 h-4 transition-transform duration-200 group-hover:scale-110"
      />
      <span class="flex items-center gap-2">
        {{ t('CAPTAIN.COPILOT.SHOW_STEPS') }}
        <span
          class="inline-flex items-center justify-center h-4 min-w-4 px-1 text-xs font-medium rounded-full bg-n-solid-3 text-n-slate-11"
        >
          {{ thinkingCount }}
        </span>
      </span>
    </button>
    <div
      v-show="isExpanded"
      class="space-y-3 transition-all duration-200"
      :class="{
        'opacity-100': isExpanded,
        'opacity-0 max-h-0 overflow-hidden': !isExpanded,
      }"
    >
      <CopilotThinkingBlock
        v-for="message in messages"
        :key="message.id"
        :content="message.content"
        :reasoning="message.reasoning"
      />
    </div>
  </div>
</template>
