<script setup>
import { computed, ref } from 'vue';
import BaseBubble from 'next/message/bubbles/Base.vue';
import FormattedContent from './FormattedContent.vue';
import AttachmentChips from 'next/message/chips/AttachmentChips.vue';
import TranslationToggle from 'dashboard/components-next/message/TranslationToggle.vue';
import { MESSAGE_TYPES } from '../../constants';
import { useMessageContext } from '../../provider.js';
import { useTranslations } from 'dashboard/composables/useTranslations';

// Truncate plain-text messages longer than this many characters and reveal
// the rest behind a "Show more" toggle. Keeps long API / paste content from
// monopolising the agent view.
const LONG_MESSAGE_CHAR_LIMIT = 800;

const { content, attachments, contentAttributes, messageType } =
  useMessageContext();

const { hasTranslations, translationContent } =
  useTranslations(contentAttributes);

const renderOriginal = ref(false);
const isExpanded = ref(false);

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

const isTruncatable = computed(() => {
  return (
    typeof renderContent.value === 'string' &&
    renderContent.value.length > LONG_MESSAGE_CHAR_LIMIT
  );
});

const displayedContent = computed(() => {
  if (!isTruncatable.value || isExpanded.value) {
    return renderContent.value;
  }
  return `${renderContent.value.slice(0, LONG_MESSAGE_CHAR_LIMIT)}…`;
});

const handleSeeOriginal = () => {
  renderOriginal.value = !renderOriginal.value;
};

const toggleExpanded = () => {
  isExpanded.value = !isExpanded.value;
};
</script>

<template>
  <BaseBubble class="px-4 py-3" data-bubble-name="text">
    <div class="gap-3 flex flex-col">
      <span v-if="isEmpty" class="text-n-slate-11">
        {{ $t('CONVERSATION.NO_CONTENT') }}
      </span>
      <FormattedContent v-if="displayedContent" :content="displayedContent" />
      <button
        v-if="isTruncatable"
        type="button"
        class="text-start text-xs font-medium text-n-slate-11 cursor-pointer hover:text-n-brand hover:underline select-none"
        @click="toggleExpanded"
      >
        {{
          isExpanded
            ? $t('CONVERSATION.SHOW_LESS')
            : $t('CONVERSATION.SHOW_MORE')
        }}
      </button>
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
