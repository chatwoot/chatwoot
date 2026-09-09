<script setup>
import { computed, ref } from 'vue';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { useI18n } from 'vue-i18n';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  quotedEmailText: {
    type: String,
    required: true,
  },
  header: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['remove']);

const { t } = useI18n();
const { formatMessage } = useMessageFormatter();

const isExpanded = ref(false);

const formattedQuotedEmailText = computed(() =>
  formatMessage(props.quotedEmailText, false, false, true)
);

const toggleTooltip = computed(() =>
  isExpanded.value
    ? t('CONVERSATION.REPLYBOX.QUOTED_REPLY.HIDE_TOOLTIP')
    : t('CONVERSATION.REPLYBOX.QUOTED_REPLY.SHOW_TOOLTIP')
);

const toggleExpand = () => {
  isExpanded.value = !isExpanded.value;
};
</script>

<template>
  <div class="mt-1">
    <div class="flex items-center gap-1">
      <button
        v-tooltip="toggleTooltip"
        type="button"
        class="inline-flex items-center justify-center h-4 rounded-md w-7 bg-n-alpha-2 text-n-slate-11 hover:bg-n-alpha-3 hover:text-n-slate-12"
        :aria-label="toggleTooltip"
        :aria-expanded="isExpanded"
        @click="toggleExpand"
      >
        <span class="i-lucide-ellipsis size-3.5" />
      </button>
      <NextButton
        v-if="isExpanded"
        v-tooltip="t('CONVERSATION.REPLYBOX.QUOTED_REPLY.REMOVE')"
        ghost
        slate
        xs
        icon="i-lucide-x"
        @click="emit('remove')"
      />
    </div>
    <div
      v-if="isExpanded"
      class="mt-2 overflow-y-auto text-sm max-h-60 text-n-slate-11"
    >
      <p v-if="header" class="mb-1">{{ header }}</p>
      <div
        v-dompurify-html="formattedQuotedEmailText"
        class="w-full max-w-none break-words border-s-2 border-n-slate-6 ps-3 prose prose-sm dark:prose-invert"
      />
    </div>
  </div>
</template>
