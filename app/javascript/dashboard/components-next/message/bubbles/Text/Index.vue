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
import {
  findComponentByType,
  COMPONENT_TYPES,
} from 'dashboard/helper/templateHelper';

const { content, attachments, contentAttributes, messageType, inboxId } =
  useMessageContext();

const { hasTranslations, translationContent } =
  useTranslations(contentAttributes);

const renderOriginal = ref(false);

const whatsAppTemplates = useFunctionGetter(
  'inboxes/getFilteredWhatsAppTemplates',
  inboxId
);

// A WhatsApp template message keeps its template metadata in
// `template_params` regardless of whether the builder stored it as a
// TEMPLATE or a plain OUTGOING message (templates sent from the composer are
// outgoing). We key on the presence of those params, and match the inbox
// template by name AND language so localized variants render the right
// buttons.
const templateButtons = computed(() => {
  const params = contentAttributes.value?.template_params;
  if (!params?.name) {
    return [];
  }

  const template = whatsAppTemplates.value.find(candidate => {
    if (candidate.name !== params.name) {
      return false;
    }
    if (params.language && candidate.language) {
      return candidate.language.toLowerCase() === params.language.toLowerCase();
    }
    return true;
  });

  const buttonComponent = template
    ? findComponentByType(template, COMPONENT_TYPES.BUTTONS)
    : null;

  return buttonComponent?.buttons ?? [];
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
      </template>
      <TemplateButtons
        v-if="templateButtons.length"
        :buttons="templateButtons"
      />
    </div>
  </BaseBubble>
</template>

<style>
p:last-child {
  margin-bottom: 0;
}
</style>
