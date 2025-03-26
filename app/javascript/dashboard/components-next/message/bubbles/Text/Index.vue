<script setup>
import { computed, ref } from 'vue';
import BaseBubble from 'next/message/bubbles/Base.vue';
import FormattedContent from './FormattedContent.vue';
import AttachmentChips from 'next/message/chips/AttachmentChips.vue';
import { MESSAGE_TYPES } from '../../constants';
import { useMessageContext } from '../../provider.js';

const { content, attachments, contentAttributes, messageType } =
  useMessageContext();

const hasTranslations = computed(() => {
  const { translations = {} } = contentAttributes.value;
  return Object.keys(translations || {}).length > 0;
});

const renderOriginal = ref(false);

const renderContent = computed(() => {
  if (renderOriginal.value) {
    return content.value;
  }

  if (hasTranslations.value) {
    const translations = contentAttributes.value.translations;
    return translations[Object.keys(translations)[0]];
  }

  return content.value;
});

const isTemplate = computed(() => {
  return messageType.value === MESSAGE_TYPES.TEMPLATE;
});

const isEmpty = computed(() => {
  return !content.value && !attachments.value?.length;
});

const viewToggleKey = computed(() => {
  return renderOriginal.value
    ? 'CONVERSATION.VIEW_TRANSLATED'
    : 'CONVERSATION.VIEW_ORIGINAL';
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
      <span class="-mt-3">
        <span
          v-if="hasTranslations"
          class="text-xs text-n-slate-11 cursor-pointer hover:underline"
          @click="handleSeeOriginal"
        >
          {{ $t(viewToggleKey) }}
        </span>
      </span>
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
