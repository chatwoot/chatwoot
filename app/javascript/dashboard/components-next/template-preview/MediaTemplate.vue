<script setup>
import { computed } from 'vue';
import FileIcon from 'dashboard/components-next/icon/FileIcon.vue';

const props = defineProps({
  message: {
    type: Object,
    required: true,
  },
});

const PDF_EXTENSIONS = ['.pdf', 'pdf'];
const VIDEO_EXTENSIONS = ['.mp4', '.mov', 'video'];
const DOC_EXTENSIONS = ['.doc'];

const mediaType = computed(() => {
  if (props.message.mediaType) return props.message.mediaType;

  const format = props.message.header?.format;
  if (format) return format.toLowerCase();

  const url = props.message.image_url || '';
  if (PDF_EXTENSIONS.some(ext => url.includes(ext))) return 'document';
  if (VIDEO_EXTENSIONS.some(ext => url.includes(ext))) return 'video';
  return 'image';
});

const fileType = computed(() => {
  const url = props.message.image_url || '';
  return DOC_EXTENSIONS.some(ext => url.includes(ext)) ? 'doc' : 'pdf';
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
      class="overflow-hidden relative rounded-lg"
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
