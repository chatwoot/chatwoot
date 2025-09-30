<script setup>
import { computed } from 'vue';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  quotedEmailText: {
    type: String,
    required: true,
  },
  isExpanded: {
    type: Boolean,
    default: false,
  },
  previewText: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['expand', 'toggle']);

const { t } = useI18n();
const { formatMessage } = useMessageFormatter();

const formattedQuotedEmailText = computed(() => {
  if (!props.quotedEmailText) {
    return '';
  }
  return formatMessage(props.quotedEmailText, false, false, true);
});
</script>

<template>
  <div class="mt-2">
    <div
      v-if="!isExpanded"
      class="flex max-w-full justify-between cursor-pointer items-center gap-2 rounded-md bg-n-slate-3 ps-3 p-1 text-xs text-n-slate-12 dark:bg-n-solid-3"
      @click="emit('expand')"
    >
      <span class="truncate" :title="previewText">
        {{ previewText }}
      </span>
      <button
        type="button"
        class="flex-shrink-0 flex items-center justify-center rounded-full hover:bg-n-slate-5"
        :aria-label="t('CONVERSATION.REPLYBOX.QUOTED_REPLY.REMOVE_PREVIEW')"
        @click.stop="emit('toggle')"
      >
        <i class="i-ph-x text-sm" />
      </button>
    </div>
    <div
      v-else
      class="rounded-md border border-dashed border-n-weak bg-n-slate-1 px-3 py-2 text-xs text-n-slate-12 dark:bg-n-solid-2"
    >
      <div class="mb-2 flex items-start justify-end gap-2">
        <button
          type="button"
          class="flex-shrink-0 rounded-full p-1 hover:bg-n-slate-4"
          :aria-label="t('CONVERSATION.REPLYBOX.QUOTED_REPLY.REMOVE_PREVIEW')"
          @click="emit('toggle')"
        >
          <i class="i-ph-x text-sm" />
        </button>
      </div>
      <div
        v-dompurify-html="formattedQuotedEmailText"
        class="max-h-60 overflow-y-auto w-full max-w-none break-words prose prose-sm dark:prose-invert"
      />
    </div>
  </div>
</template>
