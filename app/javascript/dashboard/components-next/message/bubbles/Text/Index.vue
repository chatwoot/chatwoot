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

const templateButtons = computed(() => {
  return contentAttributes.value?.templateButtons ?? [];
});

const buttonHint = button => {
  if (button.url) return button.url;
  if (button.phoneNumber) return button.phoneNumber;
  if (button.copyCode) return button.copyCode;
  return '';
};

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
      <TranslationToggle
        v-if="hasTranslations"
        class="-mt-3"
        :showing-original="renderOriginal"
        @toggle="handleSeeOriginal"
      />
      <AttachmentChips :attachments="attachments" class="gap-2" />
      <div
        v-if="templateButtons.length"
        class="flex flex-col gap-1.5 pt-1 border-t border-n-alpha-2"
      >
        <div
          v-for="(button, index) in templateButtons"
          :key="index"
          class="flex flex-col gap-0.5 px-2 py-1.5 rounded-lg bg-n-alpha-3"
        >
          <span class="text-sm font-medium text-n-blue-11">
            {{ button.text || button.type }}
          </span>
          <span
            v-if="buttonHint(button)"
            class="text-xs break-all text-n-slate-11"
          >
            {{ buttonHint(button) }}
          </span>
        </div>
      </div>
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
