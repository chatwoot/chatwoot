<script setup>
import FileIcon from './FileIcon.vue';
const files = [
  { name: 'file.7z', type: '7z' },
  { name: 'file.zip', type: 'zip' },
  { name: 'file.rar', type: 'rar' },
  { name: 'file.tar', type: 'tar' },
  { name: 'file.csv', type: 'csv' },
  { name: 'file.docx', type: 'docx' },
  { name: 'file.doc', type: 'doc' },
  { name: 'file.odt', type: 'odt' },
  { name: 'file.pdf', type: 'pdf' },
  { name: 'file.ppt', type: 'ppt' },
  { name: 'file.pptx', type: 'pptx' },
  { name: 'file.rtf', type: 'rtf' },
  { name: 'file.json', type: 'json' },
  { name: 'file.txt', type: 'txt' },
  { name: 'file.xls', type: 'xls' },
  { name: 'file.xlsx', type: 'xlsx' },
];
</script>

<template>
  <Story title="Components/Icons/FileIcon">
    <div class="grid grid-cols-4 gap-5">
      <div
        v-for="file in files"
        :key="file.type"
        class="flex items-center gap-2"
      >
        <FileIcon :file-type="file.type" class="size-6" />
        <p>{{ file.name }}</p>
      </div>
    </div>
  </Story>
</template>
