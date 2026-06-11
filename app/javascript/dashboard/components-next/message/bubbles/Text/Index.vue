<script setup>
import { computed, ref } from 'vue';
import BaseBubble from 'next/message/bubbles/Base.vue';
import FormattedContent from './FormattedContent.vue';
import AttachmentChips from 'next/message/chips/AttachmentChips.vue';
import TemplateButtons from './TemplateButtons.vue';
import TranslationToggle from 'dashboard/components-next/message/TranslationToggle.vue';
import { MESSAGE_TYPES } from '../../constants';
import { useMessageContext } from '../../provider.js';
import { useTranslations } from 'dashboard/composables/useTranslations';
import { useFunctionGetter } from 'dashboard/composables/store';
import { findComponentByType, COMPONENT_TYPES } from 'dashboard/helper/templateHelper';

const { content, attachments, contentAttributes, messageType, inboxId } =
  useMessageContext();

const { hasTranslations, translationContent } =
  useTranslations(contentAttributes);

const renderOriginal = ref(false);

const whatsAppTemplates = useFunctionGetter(
  'inboxes/getFilteredWhatsAppTemplates',
  inboxId
);

const getTemplateButtons = computed(() => {
  if (!isTemplate.value || !contentAttributes.value?.template_params?.name) {
    return [];
  }

  const templateName = contentAttributes.value.template_params.name;
  const template = whatsAppTemplates.value.find(t => t.name === templateName);

  if (!template) {
    return [];
  }

  const buttonComponent = findComponentByType(template, COMPONENT_TYPES.BUTTONS);
  return buttonComponent?.buttons || [];
});

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
      <template v-if="isTemplate">
        <div
          v-if="contentAttributes.submittedEmail"
          class="px-2 py-1 rounded-lg bg-n-alpha-3"
        >
          {{ contentAttributes.submittedEmail }}
        </div>
        <TemplateButtons v-if="getTemplateButtons.length" :buttons="getTemplateButtons" />
      </template>
    </div>
  </BaseBubble>
</template>

<style>
p:last-child {
  margin-bottom: 0;
}
</style>
