<script setup>
import { computed } from 'vue';
import Icon from 'next/icon/Icon.vue';

const { fileType } = defineProps({
  fileType: {
    type: String,
    required: true,
  },
});

const fileTypeIcon = computed(() => {
  const fileIconMap = {
    '7z': 'i-woot-file-zip',
    csv: 'i-woot-file-csv',
    doc: 'i-woot-file-doc',
    docx: 'i-woot-file-doc',
    json: 'i-woot-file-txt',
    odt: 'i-woot-file-doc',
    pdf: 'i-woot-file-pdf',
    ppt: 'i-woot-file-ppt',
    pptx: 'i-woot-file-ppt',
    rar: 'i-woot-file-zip',
    rtf: 'i-woot-file-doc',
    tar: 'i-woot-file-zip',
    txt: 'i-woot-file-txt',
    xls: 'i-woot-file-xls',
    xlsx: 'i-woot-file-xls',
    zip: 'i-woot-file-zip',
  };

  return fileIconMap[fileType] || 'i-teenyicons-text-document-solid';
});
</script>

<template>
  <Icon :icon="fileTypeIcon" />
</template>
