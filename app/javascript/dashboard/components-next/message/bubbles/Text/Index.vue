<script setup>
import TranslationToggle from 'dashboard/components-next/message/TranslationToggle.vue';
import { useTranslations } from 'dashboard/composables/useTranslations';
import BaseBubble from 'next/message/bubbles/Base.vue';
import AttachmentChips from 'next/message/chips/AttachmentChips.vue';
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { MESSAGE_TYPES } from '../../constants';
import { useMessageContext } from '../../provider.js';
import FormattedContent from './FormattedContent.vue';

const TRUNCATION_LENGTH = 800;

const { content, attachments, contentAttributes, messageType } =
  useMessageContext();

const { t } = useI18n();
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

const isLong = computed(
  () => (renderContent.value?.length ?? 0) > TRUNCATION_LENGTH
);

const isTemplate = computed(() => {
  return messageType.value === MESSAGE_TYPES.TEMPLATE;
});

const isEmpty = computed(() => {
  return !content.value && !attachments.value?.length;
});

const handleSeeOriginal = () => {
  renderOriginal.value = !renderOriginal.value;
};

const toggleExpanded = () => {
  isExpanded.value = !isExpanded.value;
};

const contentHeightClass = computed(() =>
  isLong.value && !isExpanded.value ? 'max-h-[320px]' : 'max-h-none'
);
</script>

<template>
  <BaseBubble class="px-4 py-3" data-bubble-name="text">
    <div class="gap-3 flex flex-col">
      <span v-if="isEmpty" class="text-n-slate-11">
        {{ $t('CONVERSATION.NO_CONTENT') }}
      </span>
      <div v-if="renderContent">
        <div class="relative">
          <div
            class="overflow-hidden transition-all duration-300"
            :class="contentHeightClass"
          >
            <FormattedContent :content="renderContent" />
          </div>
          <div
            v-if="isLong && !isExpanded"
            class="absolute bottom-0 left-0 right-0 h-16 bg-gradient-to-t from-n-background to-transparent pointer-events-none"
          />
        </div>
        <button
          v-if="isLong"
          class="text-n-brand text-sm mt-1 hover:underline"
          @click.stop="toggleExpanded"
        >
          {{ isExpanded ? t('MESSAGE.READ_LESS') : t('MESSAGE.READ_MORE') }}
        </button>
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
