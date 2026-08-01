<script setup>
import { computed, ref } from 'vue';
import BaseBubble from 'next/message/bubbles/Base.vue';
import FormattedContent from './FormattedContent.vue';
import AttachmentChips from 'next/message/chips/AttachmentChips.vue';
import TranslationToggle from 'dashboard/components-next/message/TranslationToggle.vue';
import { MESSAGE_TYPES } from '../../constants';
import { useMessageContext } from '../../provider.js';
import { useTranslations } from 'dashboard/composables/useTranslations';

const { content, attachments, contentAttributes, messageType } =
  useMessageContext();

const { hasTranslations, translationContent } =
  useTranslations(contentAttributes);

const renderOriginal = ref(false);

const renderContent = computed(() => {
  if (renderOriginal.value) {
    return content.value;
  }

  if (hasTranslations.value) {
    return translationContent.value;
  }

  return content.value;
});

const isTemplate = computed(() => {
  return messageType.value === MESSAGE_TYPES.TEMPLATE;
});

const isEmpty = computed(() => {
  return !content.value && !attachments.value?.length;
});

const selectedReply = computed(
  () => contentAttributes.value?.selected_reply || {}
);

const selectedReplyCardTitle = computed(
  () => selectedReply.value?.card_title || ''
);

const selectedReplyCardDescription = computed(
  () => selectedReply.value?.card_description || ''
);

const selectedReplySectionTitle = computed(
  () => selectedReply.value?.section_title || ''
);

const hasSelectedReplyContext = computed(() => {
  return !!(selectedReplyCardTitle.value || selectedReplySectionTitle.value);
});

const handleSeeOriginal = () => {
  renderOriginal.value = !renderOriginal.value;
};
</script>

<template>
  <BaseBubble class="px-4 py-3" data-bubble-name="text">
    <div class="gap-3 flex flex-col">
      <span v-if="isEmpty" class="text-n-slate-11">
        {{ $t('CONVERSATION.NO_CONTENT') }}
      </span>
      <FormattedContent v-if="renderContent" :content="renderContent" />
      <div
        v-if="hasSelectedReplyContext"
        class="px-3 py-2 rounded-lg bg-n-alpha-2 flex flex-col gap-1 text-sm"
      >
        <p v-if="selectedReplyCardTitle" class="text-n-slate-12 font-medium">
          {{
            $t('CONVERSATION.SELECTED_REPLY_CONTEXT.ITEM', {
              title: selectedReplyCardTitle,
            })
          }}
        </p>
        <p
          v-if="selectedReplyCardDescription"
          class="text-n-slate-11 whitespace-pre-wrap break-words"
        >
          {{ selectedReplyCardDescription }}
        </p>
        <p
          v-if="selectedReplySectionTitle"
          class="text-n-slate-11 whitespace-pre-wrap break-words"
        >
          {{
            $t('CONVERSATION.SELECTED_REPLY_CONTEXT.SECTION', {
              title: selectedReplySectionTitle,
            })
          }}
        </p>
      </div>
      <TranslationToggle
        v-if="hasTranslations"
        class="-mt-3"
        :showing-original="renderOriginal"
        @toggle="handleSeeOriginal"
      />
      <AttachmentChips :attachments="attachments" class="gap-2" />
      <template v-if="isTemplate">
        <div
          v-if="contentAttributes.submittedEmail"
          class="px-2 py-1 rounded-lg bg-n-alpha-3"
        >
          {{ contentAttributes.submittedEmail }}
        </div>
      </template>
    </div>
  </BaseBubble>
</template>

<style>
p:last-child {
  margin-bottom: 0;
}
</style>
