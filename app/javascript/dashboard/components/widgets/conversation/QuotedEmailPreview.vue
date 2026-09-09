<script setup>
import {
  computed,
  inject,
  nextTick,
  onBeforeUnmount,
  ref,
  useTemplateRef,
} from 'vue';
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

// Matches max-h-60 on the expanded content below
const MAX_EXPANDED_CONTENT_HEIGHT = 240;

const rootRef = useTemplateRef('rootRef');
const contentRef = useTemplateRef('contentRef');
const requestEditorHeight = inject('requestEditorHeight', () => {});

const isExpanded = ref(false);

const formattedQuotedEmailText = computed(() =>
  formatMessage(props.quotedEmailText, false, false, true)
);

const toggleTooltip = computed(() =>
  isExpanded.value
    ? t('CONVERSATION.REPLYBOX.QUOTED_REPLY.HIDE_TOOLTIP')
    : t('CONVERSATION.REPLYBOX.QUOTED_REPLY.SHOW_TOOLTIP')
);

const toggleExpand = async () => {
  isExpanded.value = !isExpanded.value;
  if (!isExpanded.value) {
    requestEditorHeight(0);
    return;
  }

  // Measure after nextTick — v-dompurify-html fills the pane a tick later.
  await nextTick();
  if (!rootRef.value || !contentRef.value) return;
  const bodyHeight = rootRef.value.parentElement.offsetHeight;
  const quoteHeight = Math.min(
    contentRef.value.scrollHeight,
    MAX_EXPANDED_CONTENT_HEIGHT
  );
  requestEditorHeight(bodyHeight + quoteHeight);
};

onBeforeUnmount(() => requestEditorHeight(0));
</script>

<template>
  <div ref="rootRef" class="flex flex-col mt-1 min-h-0">
    <div class="flex items-center gap-1 shrink-0">
      <NextButton
        v-tooltip="toggleTooltip"
        type="button"
        class="!h-4 !w-7"
        slate
        faded
        xs
        icon="i-lucide-ellipsis"
        :aria-label="toggleTooltip"
        :aria-expanded="isExpanded"
        @click="toggleExpand"
      />
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
      ref="contentRef"
      class="mt-2 overflow-y-auto text-sm max-h-60 min-h-0 text-n-slate-11"
    >
      <p v-if="header" class="mb-1">{{ header }}</p>
      <div
        v-dompurify-html="formattedQuotedEmailText"
        class="w-full max-w-none break-words border-s-2 border-n-slate-6 ps-3 prose prose-sm dark:prose-invert"
      />
    </div>
  </div>
</template>
