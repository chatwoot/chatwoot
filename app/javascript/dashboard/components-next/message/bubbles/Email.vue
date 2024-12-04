<script setup>
import { computed, useTemplateRef, ref, watch } from 'vue';
import { Letter } from 'vue-letter';
import Icon from 'next/icon/Icon.vue';
import BaseBubble from 'next/message/bubbles/Base.vue';

import ImageChip from 'next/message/chips/Image.vue';
import VideoChip from 'next/message/chips/Video.vue';
import AudioChip from 'next/message/chips/Audio.vue';
import FileChip from 'next/message/chips/File.vue';

import { MESSAGE_STATUS } from '../constants';
import { ATTACHMENT_TYPES } from '../constants';

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

const hasError = computed(() => {
  return props.status === MESSAGE_STATUS.FAILED;
});

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

const mediaAttachments = computed(() => {
  const allowedTypes = [ATTACHMENT_TYPES.IMAGE, ATTACHMENT_TYPES.VIDEO];
  const mediaTypes = props.attachments.filter(attachment =>
    allowedTypes.includes(attachment.fileType)
  );

  return mediaTypes.sort(
    (a, b) =>
      allowedTypes.indexOf(a.fileType) - allowedTypes.indexOf(b.fileType)
  );
});

const recordings = computed(() => {
  return props.attachments.filter(
    attachment => attachment.fileType === ATTACHMENT_TYPES.AUDIO
  );
});

const files = computed(() => {
  return props.attachments.filter(
    attachment => attachment.fileType === ATTACHMENT_TYPES.FILE
  );
});
</script>

<template>
  <BaseBubble class="w-full overflow-hidden">
    <section
      v-if="showMeta"
      class="p-4 space-y-1 pr-9 border-b border-n-strong"
      :class="hasError ? 'text-n-ruby-11' : 'text-n-slate-11'"
    >
      <div v-if="fromEmail[0]">
        <span :class="hasError ? 'text-n-ruby-11' : 'text-n-slate-12'">
          {{ senderName }}
        </span>
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
    </section>
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
    <section class="p-4">
      <div v-if="mediaAttachments.length" class="flex flex-wrap gap-2">
        <template v-for="attachment in mediaAttachments" :key="attachment.id">
          <ImageChip
            v-if="attachment.fileType === ATTACHMENT_TYPES.IMAGE"
            :attachment="attachment"
          />
          <VideoChip
            v-else-if="attachment.fileType === ATTACHMENT_TYPES.VIDEO"
            :attachment="attachment"
          />
        </template>
      </div>
      <div v-if="recordings.length" class="flex flex-wrap gap-2">
        <AudioChip
          v-for="attachment in recordings"
          :key="attachment.id"
          class="bg-n-alpha-3 dark:bg-n-alpha-2 text-n-slate-12"
          :attachment="attachment"
        />
      </div>
      <div v-if="files.length" class="flex flex-wrap gap-2">
        <FileChip
          v-for="attachment in files"
          :key="attachment.id"
          :attachment="attachment"
        />
      </div>
    </section>
  </BaseBubble>
</template>
