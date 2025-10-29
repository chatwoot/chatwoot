<script setup>
import { computed, useTemplateRef, ref, onMounted } from 'vue';
import { Letter } from 'vue-letter';
import { allowedCssProperties } from 'lettersanitizer';

import Icon from 'next/icon/Icon.vue';
import { EmailQuoteExtractor } from './removeReply.js';
import BaseBubble from 'next/message/bubbles/Base.vue';
import FormattedContent from 'next/message/bubbles/Text/FormattedContent.vue';
import AttachmentChips from 'next/message/chips/AttachmentChips.vue';
import EmailMeta from './EmailMeta.vue';
import TranslationToggle from 'dashboard/components-next/message/TranslationToggle.vue';

import { useMessageContext } from '../../provider.js';
import { MESSAGE_TYPES } from 'next/message/constants.js';
import { useTranslations } from 'dashboard/composables/useTranslations';

const { content, contentAttributes, attachments, messageType } =
  useMessageContext();

const isExpandable = ref(false);
const isExpanded = ref(false);
const showQuotedMessage = ref(false);
const renderOriginal = ref(false);
const contentContainer = useTemplateRef('contentContainer');

onMounted(() => {
  isExpandable.value = contentContainer.value?.scrollHeight > 400;
});

const isOutgoing = computed(() => messageType.value === MESSAGE_TYPES.OUTGOING);
const isIncoming = computed(() => !isOutgoing.value);

const { hasTranslations, translationContent } =
  useTranslations(contentAttributes);

const originalEmailText = computed(() => {
  const text =
    contentAttributes?.value?.email?.textContent?.full ?? content.value;
  return text?.replace(/\n/g, '<br>');
});

const originalEmailHtml = computed(
  () =>
    contentAttributes?.value?.email?.htmlContent?.full ??
    originalEmailText.value
);

const messageContent = computed(() => {
  // If translations exist and we're showing translations (not original)
  if (hasTranslations.value && !renderOriginal.value) {
    return translationContent.value;
  }
  // Otherwise show original content
  return content.value;
});

const textToShow = computed(() => {
  // If translations exist and we're showing translations (not original)
  if (hasTranslations.value && !renderOriginal.value) {
    return translationContent.value;
  }
  // Otherwise show original text
  return originalEmailText.value;
});

const fullHTML = computed(() => {
  // If translations exist and we're showing translations (not original)
  if (hasTranslations.value && !renderOriginal.value) {
    return translationContent.value;
  }
  // Otherwise show original HTML
  return originalEmailHtml.value;
});

const unquotedHTML = computed(() =>
  EmailQuoteExtractor.extractQuotes(fullHTML.value)
);

const hasQuotedMessage = computed(() =>
  EmailQuoteExtractor.hasQuotes(fullHTML.value)
);

// Ensure unique keys for <Letter> when toggling between original and translated views.
// This forces Vue to re-render the component and update content correctly.
const translationKeySuffix = computed(() => {
  if (renderOriginal.value) return 'original';
  if (hasTranslations.value) return 'translated';
  return 'original';
});

const handleSeeOriginal = () => {
  renderOriginal.value = !renderOriginal.value;
};
</script>

<template>
  <BaseBubble
    class="w-full"
    :class="{
      'bg-n-slate-4': isIncoming,
      'bg-n-solid-blue': isOutgoing,
    }"
    data-bubble-name="email"
  >
    <EmailMeta
      class="p-3"
      :class="{
        'border-b border-n-strong': isIncoming,
        'border-b border-n-slate-8/20': isOutgoing,
      }"
    />
    <section ref="contentContainer" class="p-3">
      <div
        :class="{
          'max-h-[400px] overflow-hidden relative': !isExpanded && isExpandable,
          'overflow-y-scroll relative': isExpanded,
        }"
      >
        <div
          v-if="isExpandable && !isExpanded"
          class="absolute left-0 right-0 bottom-0 h-40 px-8 flex items-end bg-gradient-to-t from-n-slate-4 via-n-slate-4 via-20% to-transparent"
        >
          <button
            class="text-n-slate-12 py-2 px-8 mx-auto text-center flex items-center gap-2"
            @click="isExpanded = true"
          >
            <Icon icon="i-lucide-maximize-2" />
            {{ $t('EMAIL_HEADER.EXPAND') }}
          </button>
        </div>
        <FormattedContent
          v-if="isOutgoing && content"
          class="text-n-slate-12"
          :content="messageContent"
        />
        <template v-else>
          <Letter
            v-if="showQuotedMessage"
            :key="`letter-quoted-${translationKeySuffix}`"
            class-name="prose prose-bubble !max-w-none letter-render"
            :allowed-css-properties="[
              ...allowedCssProperties,
              'transform',
              'transform-origin',
            ]"
            :html="fullHTML"
            :text="textToShow"
          />
          <Letter
            v-else
            :key="`letter-unquoted-${translationKeySuffix}`"
            class-name="prose prose-bubble !max-w-none letter-render"
            :html="unquotedHTML"
            :allowed-css-properties="[
              ...allowedCssProperties,
              'transform',
              'transform-origin',
            ]"
            :text="textToShow"
          />
        </template>
        <button
          v-if="hasQuotedMessage"
          class="text-n-slate-11 px-1 leading-none text-sm bg-n-alpha-black2 text-center flex items-center gap-1 mt-2"
          @click="showQuotedMessage = !showQuotedMessage"
        >
          <template v-if="showQuotedMessage">
            {{ $t('CHAT_LIST.HIDE_QUOTED_TEXT') }}
          </template>
          <template v-else>
            {{ $t('CHAT_LIST.SHOW_QUOTED_TEXT') }}
          </template>
          <Icon
            :icon="
              showQuotedMessage
                ? 'i-lucide-chevron-up'
                : 'i-lucide-chevron-down'
            "
          />
        </button>
      </div>
    </section>
    <TranslationToggle
      v-if="hasTranslations"
      class="py-2 px-3"
      :showing-original="renderOriginal"
      @toggle="handleSeeOriginal"
    />
    <section
      v-if="Array.isArray(attachments) && attachments.length"
      class="px-4 pb-4 space-y-2"
    >
      <AttachmentChips :attachments="attachments" class="gap-1" />
    </section>
  </BaseBubble>
</template>

<style lang="scss">
// Tailwind resets break the rendering of google drive link in Gmail messages
// This fixes it using https://developer.mozilla.org/en-US/docs/Web/CSS/Attribute_selectors

.letter-render [class*='gmail_drive_chip'] {
  box-sizing: initial;
  @apply bg-n-slate-4 border-n-slate-6 rounded-md !important;

  a {
    @apply text-n-slate-12 !important;

    img {
      display: inline-block;
    }
  }
}
</style>
