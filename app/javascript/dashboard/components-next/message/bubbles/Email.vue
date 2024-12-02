<script setup>
import { computed, useTemplateRef, ref, watch } from 'vue';
import { Letter } from 'vue-letter';
import Button from 'next/button/Button.vue';
import BaseBubble from 'next/message/bubbles/Base.vue';

const props = defineProps({
  content: {
    type: String,
    required: true,
  },
  contentAttributes: {
    type: Object,
    default: () => ({}),
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
  return props.contentAttributes?.email?.textContent?.full ?? props.content;
});

const fromEmail = computed(() => {
  return props.contentAttributes?.email?.from ?? [];
});

const toEmail = computed(() => {
  return props.contentAttributes?.email?.to ?? [];
});

const ccEmail = computed(() => {
  return (
    props.contentAttributes?.ccEmail ?? props.contentAttributes?.email?.cc ?? []
  );
});

const senderName = computed(() => {
  return props.sender.name ?? '';
});

const bccEmail = computed(() => {
  return (
    props.contentAttributes?.bccEmail ??
    props.contentAttributes?.email?.bcc ??
    []
  );
});

const subject = computed(() => {
  return props.contentAttributes?.email?.subject ?? '';
});

const showMeta = computed(() => {
  return (
    fromEmail.value[0] ||
    toEmail.value.length ||
    ccEmail.value.length ||
    bccEmail.value.length ||
    subject.value
  );
});
</script>

<template>
  <BaseBubble class="w-full overflow-hidden">
    <div
      v-if="showMeta"
      class="p-4 text-n-slate-11 space-y-1 pr-9 border-b border-n-strong"
    >
      <div v-if="fromEmail[0]">
        <span class="text-n-slate-12">{{ senderName }}</span>
        &lt;{{ fromEmail[0] }}&gt;
      </div>
      <div v-if="toEmail.length">
        {{ $t('EMAIL_HEADER.TO') }}: {{ toEmail.join(', ') }}
      </div>
      <div v-if="ccEmail.length">
        {{ $t('EMAIL_HEADER.CC') }}:
        {{ ccEmail }}
      </div>
      <div v-if="bccEmail.length">
        {{ $t('EMAIL_HEADER.BCC') }}:
        {{ bccEmail }}
      </div>
      <div v-if="subject">
        {{ $t('EMAIL_HEADER.SUBJECT') }}:
        {{ subject }}
      </div>
    </div>
    <div
      ref="contentContainer"
      class="p-4"
      :class="{
        'max-h-96 overflow-hidden relative': !isExpanded,
      }"
    >
      <div
        v-if="isOverflowing && !isExpanded"
        class="absolute left-0 right-0 bottom-0 h-28 grid place-content-center bg-gradient-to-t dark:from-[#24252b] from-[#F5F5F6] dark:via-[rgba(36,37,43,0.5)] via-[rgba(245,245,246,0.50)] dark:to-transparent to-[rgba(245,245,246,0.00)]"
      >
        <Button
          icon="i-lucide-maximize-2"
          ghost
          slate
          class="text-n-slate-1"
          @click="isExpanded = true"
        >
          {{ $t('EMAIL_HEADER.EXPAND') }}:
        </Button>
      </div>
      <Letter
        class-name="prose prose-email"
        :html="contentToShow"
        :text="textToShow"
      />
    </div>
  </BaseBubble>
</template>
