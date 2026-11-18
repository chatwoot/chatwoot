<script setup>
import { useI18n } from 'vue-i18n';

defineProps({
  // Each item comes from ChatAttachment: { file, thumbUrl, fileType, fileName }.
  attachments: { type: Array, required: true },
});

const emit = defineEmits(['remove']);

const { t } = useI18n();
</script>

<template>
  <ul class="flex flex-wrap gap-2 pt-2 pe-1">
    <li
      v-for="(attachment, index) in attachments"
      :key="attachment.thumbUrl"
      class="relative flex items-center gap-1.5 rounded-lg bg-n-alpha-2 text-n-slate-12"
      :class="
        attachment.fileType === 'image' ? 'size-14' : 'h-14 max-w-40 px-2'
      "
    >
      <img
        v-if="attachment.fileType === 'image'"
        :src="attachment.thumbUrl"
        :alt="attachment.fileName"
        class="object-cover rounded-lg size-14"
      />
      <template v-else>
        <span class="i-lucide-file size-5 shrink-0" />
        <span class="text-xs truncate">{{ attachment.fileName }}</span>
      </template>
      <button
        type="button"
        class="absolute flex items-center justify-center rounded-full -top-1.5 -end-1.5 size-5 bg-n-slate-12 text-n-background"
        :aria-label="
          t('PENDING_ATTACHMENTS.REMOVE', { name: attachment.fileName })
        "
        @click="emit('remove', index)"
      >
        <span class="i-lucide-x size-3" />
      </button>
    </li>
  </ul>
</template>
