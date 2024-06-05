<template>
  <div class="flex overflow-auto max-h-[12.5rem]">
    <div
      v-for="(attachment, index) in nonRecordedAudioAttachments"
      :key="attachment.id"
      class="preview-item flex items-center p-1 bg-slate-50 dark:bg-slate-800 gap-1 rounded-md w-[15rem] mb-1"
    >
      <div class="max-w-[4rem] flex-shrink-0 w-6 flex items-center">
        <img
          v-if="isTypeImage(attachment.resource)"
          class="object-cover w-6 h-6 rounded-sm"
          :src="attachment.thumb"
        />
        <span v-else class="relative w-6 h-6 text-lg text-left -top-px">
          📄
        </span>
      </div>
      <div class="max-w-3/5 min-w-[50%] overflow-hidden text-ellipsis">
        <span
          class="h-4 overflow-hidden text-sm font-medium text-ellipsis whitespace-nowrap"
        >
          {{ fileName(attachment.resource) }}
        </span>
      </div>
      <div class="w-[30%] justify-center">
        <span class="overflow-hidden text-xs text-ellipsis whitespace-nowrap">
          {{ formatFileSize(attachment.resource) }}
        </span>
      </div>
      <div class="flex items-center justify-center">
        <woot-button
          class="!w-6 !h-6 text-sm rounded-md hover:bg-slate-50 dark:hover:bg-slate-800 clear secondary"
          icon="dismiss"
          @click="onRemoveAttachment(index)"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue';
import { formatBytes } from 'shared/helpers/FileHelper';

const props = defineProps({
  attachments: {
    type: Array,
    default: () => [],
  },
});

const emits = defineEmits(['remove-attachment']);

const nonRecordedAudioAttachments = computed(() => {
  return props.attachments.filter(attachment => !attachment?.isRecordedAudio);
});

const recordedAudioAttachments = computed(() =>
  props.attachments.filter(attachment => attachment.isRecordedAudio)
);

const onRemoveAttachment = itemIndex => {
  emits(
    'remove-attachment',
    nonRecordedAudioAttachments.value
      .filter((_, index) => index !== itemIndex)
      .concat(recordedAudioAttachments.value)
  );
};

const formatFileSize = file => {
  const size = file.byte_size || file.size;
  return formatBytes(size, 0);
};

const isTypeImage = file => {
  const type = file.content_type || file.type;
  return type.includes('image');
};

const fileName = file => {
  return file.filename || file.name;
};
</script>
