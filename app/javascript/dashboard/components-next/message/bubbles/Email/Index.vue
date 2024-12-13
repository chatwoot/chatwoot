<script setup>
import { computed, useTemplateRef, ref, onMounted } from 'vue';
import { Letter } from 'vue-letter';

import Icon from 'next/icon/Icon.vue';
import { EmailQuoteExtractor } from './removeReply.js';
import BaseBubble from 'next/message/bubbles/Base.vue';
import FormattedContent from 'next/message/bubbles/Text/FormattedContent.vue';
import AttachmentChips from 'next/message/chips/AttachmentChips.vue';

import EmailMeta from './EmailMeta.vue';
import { MESSAGE_STATUS, MESSAGE_TYPES } from '../../constants';

const props = defineProps({
  content: {
    type: String,
    required: true,
  },
  contentAttributes: {
    type: Object,
    default: () => ({}),
  },
  attachments: {
    type: Array,
    default: () => [],
  },
  status: {
    type: String,
    required: true,
    validator: value => Object.values(MESSAGE_STATUS).includes(value),
  },
  sender: {
    type: Object,
    default: () => ({}),
  },
  messageType: {
    type: Number,
    required: true,
  },
});

const isExpandable = ref(false);
const isExpanded = ref(false);
const showQuotedMessage = ref(false);
const contentContainer = useTemplateRef('contentContainer');

onMounted(() => {
  isExpandable.value = contentContainer.value.scrollHeight > 400;
});

const isOutgoing = computed(() => {
  return props.messageType === MESSAGE_TYPES.OUTGOING;
});

const fullHTML = computed(() => {
  return props.contentAttributes?.email?.htmlContent?.full ?? props.content;
});

const unquotedHTML = computed(() => {
  return EmailQuoteExtractor.extractQuotes(fullHTML.value);
});

const hasQuotedMessage = computed(() => {
  return EmailQuoteExtractor.hasQuotes(fullHTML.value);
});

const textToShow = computed(() => {
  const text =
    props.contentAttributes?.email?.textContent?.full ?? props.content;
  return text.replace(/\n/g, '<br>');
});
</script>

<template>
  <BaseBubble class="w-full overflow-hidden" data-bubble-name="email">
    <EmailMeta :status :sender :content-attributes />
    <section
      ref="contentContainer"
      class="p-4"
      :class="{
        'max-h-[400px] overflow-hidden relative': !isExpanded && isExpandable,
      }"
    >
      <div
        v-if="isExpandable && !isExpanded"
        class="absolute left-0 right-0 bottom-0 h-40 p-8 flex items-end bg-gradient-to-t dark:from-[#24252b] from-[#F5F5F6] dark:via-[rgba(36,37,43,0.5)] via-[rgba(245,245,246,0.50)] dark:to-transparent to-[rgba(245,245,246,0.00)]"
      >
        <button
          class="text-n-slate-12 py-2 px-8 mx-auto text-center flex items-center gap-2"
          @click="isExpanded = true"
        >
          <Icon icon="i-lucide-maximize-2" />
          {{ $t('EMAIL_HEADER.EXPAND') }}
        </button>
      </div>
      <FormattedContent v-if="isOutgoing && content" :content="content" />
      <template v-else>
        <Letter
          v-if="showQuotedMessage"
          class-name="prose prose-email !max-w-none"
          :html="fullHTML"
          :text="textToShow"
        />
        <Letter
          v-else
          class-name="prose prose-email !max-w-none"
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
            showQuotedMessage ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'
          "
        />
      </button>
    </section>
    <section v-if="attachments.length" class="px-4 pb-4 space-y-2">
      <AttachmentChips :attachments="attachments" class="gap-1" />
    </section>
  </BaseBubble>
</template>
