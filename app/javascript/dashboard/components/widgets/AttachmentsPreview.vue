<script setup>
import { computed } from 'vue';
import { formatBytes } from 'shared/helpers/FileHelper';

import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  attachments: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['removeAttachment']);

const nonRecordedAudioAttachments = computed(() => {
  return props.attachments.filter(attachment => !attachment?.isRecordedAudio);
});

const recordedAudioAttachments = computed(() =>
  props.attachments.filter(attachment => attachment.isRecordedAudio)
);

// Create unified list of attachments with metadata for rendering
const allAttachments = computed(() => {
  const audioAttachments = recordedAudioAttachments.value.map(
    (attachment, index) => ({
      attachment,
      isRecordedAudio: true,
      index,
      key: `audio-${index}`,
    })
  );

  const otherAttachments = nonRecordedAudioAttachments.value.map(
    (attachment, index) => ({
      attachment,
      isRecordedAudio: false,
      index,
      key: attachment.id,
    })
  );

  return [...audioAttachments, ...otherAttachments];
});

const removeAttachment = (isRecordedAudio, itemIndex) => {
  if (isRecordedAudio) {
    emit(
      'removeAttachment',
      nonRecordedAudioAttachments.value.concat(
        recordedAudioAttachments.value.filter((_, index) => index !== itemIndex)
      )
    );
  } else {
    emit(
      'removeAttachment',
      nonRecordedAudioAttachments.value
        .filter((_, index) => index !== itemIndex)
        .concat(recordedAudioAttachments.value)
    );
  }
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

<template>
  <div class="flex flex-col overflow-auto max-h-[12.5rem]">
    <div
      v-for="item in allAttachments"
      :key="item.key"
      class="preview-item flex items-center p-1 bg-n-slate-9/10 gap-1 rounded-md w-[15rem] mb-1"
    >
      <div class="max-w-[4rem] flex-shrink-0 w-6 flex items-center">
        <img
          v-if="!item.isRecordedAudio && isTypeImage(item.attachment.resource)"
          class="object-cover w-6 h-6 rounded-sm"
          :src="item.attachment.thumb"
        />
        <span v-else class="relative w-6 h-6 text-lg text-left -top-px">
          {{ item.isRecordedAudio ? '🎤' : '📄' }}
        </span>
      </div>
      <div class="max-w-3/5 min-w-[50%] overflow-hidden text-ellipsis">
        <span
          class="h-4 overflow-hidden text-sm font-medium text-ellipsis whitespace-nowrap"
        >
          {{ fileName(item.attachment.resource) }}
        </span>
      </div>
      <div class="w-[30%] justify-center">
        <span class="overflow-hidden text-xs text-ellipsis whitespace-nowrap">
          {{ formatFileSize(item.attachment.resource) }}
        </span>
      </div>
      <div class="flex items-center justify-center">
        <Button
          ghost
          slate
          xs
          icon="i-lucide-x"
          @click="removeAttachment(item.isRecordedAudio, item.index)"
        />
      </div>
    </div>
  </div>
</template>
