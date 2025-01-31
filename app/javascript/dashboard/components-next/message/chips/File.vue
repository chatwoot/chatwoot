<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import FileIcon from 'next/icon/FileIcon.vue';
import Icon from 'next/icon/Icon.vue';

const { attachment } = defineProps({
  attachment: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();

const fileName = computed(() => {
  const url = attachment.dataUrl;
  if (!url) return t('CONVERSATION.UNKNOWN_FILE_TYPE');

  try {
    const encodedFilename = url.substring(url.lastIndexOf('/') + 1);
    return decodeURIComponent(encodedFilename);
  } catch {
    return t('CONVERSATION.UNKNOWN_FILE_TYPE');
  }
});

const fileType = computed(() => fileName.value.split('.').pop()?.toLowerCase());

const fileNameWithoutExt = computed(() => {
  const parts = fileName.value.split('.');

  // If there's no extension (no dots in filename)
  if (parts.length === 1) {
    return fileName.value.trim();
  }

  // Take all parts except the last one (extension)
  const nameWithoutExt = parts.slice(0, -1).join('.');
  return nameWithoutExt.trim();
});

const displayFileName = computed(() => {
  const name = fileNameWithoutExt.value;
  const truncatedName = (str, maxLength, hasExt) =>
    str.length > maxLength
      ? `${str.substring(0, maxLength).trimEnd()}${hasExt ? '..' : '...'}`
      : str;

  return fileType.value
    ? `${truncatedName(name, 14, true)}.${fileType.value}`
    : truncatedName(name, 16, false);
});

const textColorClass = computed(() => {
  const colorMap = {
    '7z': 'dark:text-[#EDEEF0] text-[#2F265F]',
    csv: 'text-amber-12',
    doc: 'dark:text-[#D6E1FF] text-[#1F2D5C]', // indigo-12
    docx: 'dark:text-[#D6E1FF] text-[#1F2D5C]', // indigo-12
    json: 'text-n-slate-12',
    odt: 'dark:text-[#D6E1FF] text-[#1F2D5C]', // indigo-12
    pdf: 'text-n-ruby-12',
    ppt: 'dark:text-[#FFE0C2] text-[#582D1D]',
    pptx: 'dark:text-[#FFE0C2] text-[#582D1D]',
    rar: 'dark:text-[#EDEEF0] text-[#2F265F]',
    rtf: 'dark:text-[#D6E1FF] text-[#1F2D5C]', // indigo-12
    tar: 'dark:text-[#EDEEF0] text-[#2F265F]',
    txt: 'text-n-slate-12',
    xls: 'text-n-teal-12',
    xlsx: 'text-n-teal-12',
    zip: 'dark:text-[#EDEEF0] text-[#2F265F]',
  };

  return colorMap[fileType.value] || 'text-n-slate-12';
});
</script>

<template>
  <div
    class="h-9 bg-n-alpha-white gap-2 overflow-hidden items-center flex px-2 rounded-lg border border-n-container"
  >
    <FileIcon class="flex-shrink-0" :file-type="fileType" />
    <span
      class="flex-1 min-w-0 text-sm max-w-36"
      :title="fileName"
      :class="textColorClass"
    >
      {{ displayFileName }}
    </span>
    <a
      v-tooltip="t('CONVERSATION.DOWNLOAD')"
      class="flex-shrink-0 size-9 grid place-content-center cursor-pointer text-n-slate-11 hover:text-n-slate-12 transition-colors"
      :href="attachment.dataUrl"
      rel="noreferrer noopener nofollow"
      target="_blank"
    >
      <Icon icon="i-lucide-download" />
    </a>
  </div>
</template>
