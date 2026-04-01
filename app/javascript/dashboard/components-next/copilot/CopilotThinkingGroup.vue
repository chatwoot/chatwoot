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
      type="button"
      class="group -ml-1 flex items-center gap-2 text-xs text-on-surface-variant transition-colors duration-200 hover:text-on-surface"
      @click="isExpanded = !isExpanded"
    >
      <Icon
        :icon="isExpanded ? 'i-lucide-chevron-down' : 'i-lucide-chevron-right'"
        class="size-4 transition-transform duration-200 group-hover:scale-110"
      />
      <span class="flex items-center gap-2">
        {{ t('CAPTAIN.COPILOT.SHOW_STEPS') }}
        <span
          class="inline-flex h-5 min-w-5 items-center justify-center rounded-full bg-surface-container-high px-1.5 text-xs font-semibold text-on-surface-variant"
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
        v-for="copilotMessage in messages"
        :key="copilotMessage.id"
        :content="copilotMessage.message.content"
        :reasoning="copilotMessage.message.reasoning"
      />
    </div>
  </div>
</template>
