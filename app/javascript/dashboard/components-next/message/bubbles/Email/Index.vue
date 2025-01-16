<script setup>
import { computed, useTemplateRef, ref, onMounted } from 'vue';
import { Letter } from 'vue-letter';

import Icon from 'next/icon/Icon.vue';
import { EmailQuoteExtractor } from './removeReply.js';
import BaseBubble from 'next/message/bubbles/Base.vue';
import FormattedContent from 'next/message/bubbles/Text/FormattedContent.vue';
import AttachmentChips from 'next/message/chips/AttachmentChips.vue';
import EmailMeta from './EmailMeta.vue';

import { useMessageContext } from '../../provider.js';
import { MESSAGE_TYPES } from 'next/message/constants.js';

const { content, contentAttributes, attachments, messageType } =
  useMessageContext();

const isExpandable = ref(false);
const isExpanded = ref(false);
const showQuotedMessage = ref(false);
const contentContainer = useTemplateRef('contentContainer');

onMounted(() => {
  isExpandable.value = contentContainer.value?.scrollHeight > 400;
});

const isOutgoing = computed(() => {
  return messageType.value === MESSAGE_TYPES.OUTGOING;
});
const isIncoming = computed(() => !isOutgoing.value);

const fullHTML = computed(() => {
  return contentAttributes?.value?.email?.htmlContent?.full ?? content.value;
});

const unquotedHTML = computed(() => {
  return EmailQuoteExtractor.extractQuotes(fullHTML.value);
});

const hasQuotedMessage = computed(() => {
  return EmailQuoteExtractor.hasQuotes(fullHTML.value);
});

const textToShow = computed(() => {
  const text =
    contentAttributes?.value?.email?.textContent?.full ?? content.value;
  return text?.replace(/\n/g, '<br>');
});
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
          class="absolute left-0 right-0 bottom-0 h-40 px-8 flex items-end bg-gradient-to-t from-n-gray-3 via-n-gray-3 via-20% to-transparent"
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
          :content="content"
        />
        <template v-else>
          <Letter
            v-if="showQuotedMessage"
            class-name="prose prose-bubble !max-w-none"
            :html="fullHTML"
            :text="textToShow"
          />
          <Letter
            v-else
            class-name="prose prose-bubble !max-w-none"
            :html="unquotedHTML"
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
    <section
      v-if="Array.isArray(attachments) && attachments.length"
      class="px-4 pb-4 space-y-2"
    >
      <AttachmentChips :attachments="attachments" class="gap-1" />
    </section>
  </BaseBubble>
</template>
