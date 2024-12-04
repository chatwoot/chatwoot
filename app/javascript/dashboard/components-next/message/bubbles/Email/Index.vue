<script setup>
import { computed, useTemplateRef, ref, watch } from 'vue';
import { Letter } from 'vue-letter';

import Icon from 'next/icon/Icon.vue';
import BaseBubble from 'next/message/bubbles/Base.vue';
import AttachmentChips from 'next/message/chips/AttachmentChips.vue';

import EmailMeta from './EmailMeta.vue';
import { MESSAGE_STATUS } from '../../constants';

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
});

const isOverflowing = ref(false);
const isExpanded = ref(false);
const contentContainer = useTemplateRef('contentContainer');

watch(
  contentContainer,
  el => {
    if (el) {
      isOverflowing.value = el.scrollHeight > el.clientHeight;
    }
  },
  { immediate: true }
);

const contentToShow = computed(() => {
  return props.contentAttributes?.email?.htmlContent?.full ?? props.content;
});

const textToShow = computed(() => {
  const text =
    props.contentAttributes?.email?.textContent?.full ?? props.content;
  return text.replace(/\n/g, '<br>');
});
</script>

<template>
  <BaseBubble class="w-full overflow-hidden">
    <EmailMeta :status :sender :content-attributes />
    <section
      ref="contentContainer"
      class="p-4"
      :class="{
        'max-h-[400px] overflow-hidden relative': !isExpanded,
      }"
    >
      <div
        v-if="isOverflowing && !isExpanded"
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
      <Letter
        class-name="prose prose-email"
        :html="contentToShow"
        :text="textToShow"
      />
    </section>
    <section class="px-4 pb-4">
      <AttachmentChips :attachments="attachments" class="gap-1" />
    </section>
  </BaseBubble>
</template>
