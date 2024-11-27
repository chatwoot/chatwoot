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
    '7z': 'i-teenyicons-zip-solid',
    csv: 'i-teenyicons-csv-solid',
    doc: 'i-teenyicons-doc-solid',
    docx: 'i-teenyicons-doc-solid',
    json: 'i-teenyicons-text-document-solid',
    odt: 'i-teenyicons-doc-solid',
    pdf: 'i-teenyicons-pdf-solid',
    ppt: 'i-teenyicons-ppt-solid',
    pptx: 'i-teenyicons-ppt-solid',
    rar: 'i-teenyicons-zip-solid',
    rtf: 'i-teenyicons-doc-solid',
    tar: 'i-teenyicons-zip-solid',
    txt: 'i-teenyicons-text-document-solid',
    xls: 'i-teenyicons-xls-solid',
    xlsx: 'i-teenyicons-xls-solid',
    zip: 'i-teenyicons-zip-solid',
  };

  return fileIconMap[fileType] || 'i-teenyicons-text-document-solid';
});

const iconColor = computed(() => {
  const colorMap = {
    'i-teenyicons-csv-solid': '#217346',
    'i-teenyicons-doc-solid': '#2B579A',
    'i-teenyicons-pdf-solid': '#FF0000',
    'i-teenyicons-ppt-solid': '#D24726',
    'i-teenyicons-text-document-solid': '#41A5EE',
    'i-teenyicons-xls-solid': '#217346',
    'i-teenyicons-zip-solid': '#FDB813',
  };

  return colorMap[fileTypeIcon.value];
});
</script>

<template>
  <Icon :icon="fileTypeIcon" :style="{ color: iconColor }" />
</template>
