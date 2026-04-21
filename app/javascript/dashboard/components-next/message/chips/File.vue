<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { getFileInfo } from '@chatwoot/utils';

import FileIcon from 'next/icon/FileIcon.vue';
import Icon from 'next/icon/Icon.vue';

const { attachment } = defineProps({
  attachment: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();

const fileDetails = computed(() => {
  return getFileInfo(attachment?.dataUrl || '');
});

const displayFileName = computed(() => {
  const { base, type } = fileDetails.value;
  const truncatedName = (str, maxLength, hasExt) =>
    str.length > maxLength
      ? `${str.substring(0, maxLength).trimEnd()}${hasExt ? '..' : '...'}`
      : str;

  return type
    ? `${truncatedName(base, 12, true)}.${type}`
    : truncatedName(base, 14, false);
});

const textColorClass = computed(() => {
  const colorMap = {
    '7z': 'dark:text-[#EDEEF0] text-[#2F265F]',
    csv: 'text-s-warning-text',
    doc: 'dark:text-[#D6E1FF] text-[#1F2D5C]', // indigo-12
    docx: 'dark:text-[#D6E1FF] text-[#1F2D5C]', // indigo-12
    json: 'text-s-primary',
    odt: 'dark:text-[#D6E1FF] text-[#1F2D5C]', // indigo-12
    pdf: 'text-s-primary',
    ppt: 'dark:text-[#FFE0C2] text-[#582D1D]',
    pptx: 'dark:text-[#FFE0C2] text-[#582D1D]',
    rar: 'dark:text-[#EDEEF0] text-[#2F265F]',
    rtf: 'dark:text-[#D6E1FF] text-[#1F2D5C]', // indigo-12
    tar: 'dark:text-[#EDEEF0] text-[#2F265F]',
    txt: 'text-s-primary',
    xls: 'text-s-success-text',
    xlsx: 'text-s-success-text',
    zip: 'dark:text-[#EDEEF0] text-[#2F265F]',
  };

  return colorMap[fileDetails.value.type] || 'text-s-primary';
});
</script>

<template>
  <div
    class="h-9 bg-s-surface gap-2 overflow-hidden items-center flex px-2 rounded-lg border border-s-border"
  >
    <FileIcon class="flex-shrink-0" :file-type="fileDetails.type" />
    <span
      class="flex-1 min-w-0 text-sm max-w-36"
      :title="fileDetails.name"
      :class="textColorClass"
    >
      {{ displayFileName }}
    </span>
    <a
      v-tooltip="t('CONVERSATION.DOWNLOAD')"
      class="flex-shrink-0 size-9 grid place-content-center cursor-pointer text-s-muted hover:text-s-primary transition-colors"
      :href="attachment.dataUrl"
      rel="noreferrer noopener nofollow"
      target="_blank"
    >
      <Icon icon="i-lucide-download" />
    </a>
  </div>
</template>
