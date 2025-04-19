<script setup>
import { computed, ref } from 'vue';
import BaseBubble from 'next/message/bubbles/Base.vue';
import FormattedContent from './FormattedContent.vue';
import AttachmentChips from 'next/message/chips/AttachmentChips.vue';
import TranslationToggle from 'dashboard/components-next/message/TranslationToggle.vue';
import { MESSAGE_TYPES, ATTACHMENT_TYPES } from '../../constants';
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

const imageAttachments = computed(() => {
  console.log('TextBubble attachments:', attachments.value); // DEBUG
  const images = attachments.value?.filter(
    attachment => {
      console.log('Checking attachment:', attachment.id, 'Type:', attachment.fileType); // DEBUG
      return attachment.fileType === ATTACHMENT_TYPES.IMAGE;
    }
  ) || [];
  console.log('Filtered image attachments:', images); // DEBUG
  return images;
});

const nonImageAttachments = computed(() => {
  return (
    attachments.value?.filter(
      attachment => attachment.fileType !== ATTACHMENT_TYPES.IMAGE
    ) || []
  );
});

const isTemplate = computed(() => {
  return messageType.value === MESSAGE_TYPES.TEMPLATE;
});

const isEmpty = computed(() => {
  return !content.value && !attachments.value?.length;
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
      <div v-if="imageAttachments.length" class="flex flex-col gap-2 mt-1">
        <div
          v-for="attachment in imageAttachments"
          :key="attachment.id"
          class="max-w-xs"
        >
          <img
            :src="attachment.dataUrl"
            class="rounded-lg object-cover w-full skip-context-menu"
            alt="Image Attachment"
          />
        </div>
      </div>
      <FormattedContent v-if="renderContent" :content="renderContent" />
      <TranslationToggle
        v-if="hasTranslations"
        class="-mt-3"
        :showing-original="renderOriginal"
        @toggle="handleSeeOriginal"
      />
      <AttachmentChips
        v-if="nonImageAttachments.length"
        :attachments="nonImageAttachments"
        class="gap-2"
      />
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
