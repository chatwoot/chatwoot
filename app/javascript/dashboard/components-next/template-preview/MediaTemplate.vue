<script setup>
import { computed } from 'vue';
import FileIcon from 'dashboard/components-next/icon/FileIcon.vue';

const props = defineProps({
  message: {
    type: Object,
    required: true,
  },
});

// Determine media type based on URL or template data
const mediaType = computed(() => {
  if (props.message.originalTemplate?.header?.format) {
    return props.message.originalTemplate.header.format.toLowerCase();
  }

  const url = props.message.image_url;
  if (!url) return 'document';

  if (url.includes('.pdf') || url.includes('pdf')) return 'document';
  if (url.includes('.mp4') || url.includes('.mov') || url.includes('video'))
    return 'video';
  return 'image';
});

// Get file type from URL for proper icon
const fileType = computed(() => {
  const url = props.message.image_url;
  if (!url) return 'pdf';

  if (url.includes('.pdf') || url.includes('pdf')) return 'pdf';
  if (url.includes('.doc')) return 'doc';
  return 'pdf'; // Default to PDF for documents
});
</script>

<template>
  <div
    class="flex flex-col gap-2.5 p-3 rounded-xl bg-n-alpha-2 text-n-slate-12 max-w-80"
  >
    <img
      v-if="mediaType === 'image'"
      :src="message.image_url"
      class="object-cover w-full max-h-44 rounded-lg"
      alt="Template media"
    />

    <div
      v-else-if="mediaType === 'video'"
      class="overflow-hidden relative bg-gray-100 rounded-lg"
    >
      <video
        :src="message.image_url"
        class="object-cover w-full max-h-44"
        controls
        preload="metadata"
      />
    </div>

    <div v-else-if="mediaType === 'document'" class="flex items-center">
      <FileIcon :file-type="fileType" class="text-2xl text-n-slate-12" />
    </div>

    <span
      v-if="message.content"
      v-dompurify-html="message.content"
      class="text-sm font-medium prose prose-bubble"
    />
  </div>
</template>
