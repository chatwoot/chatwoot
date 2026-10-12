<script setup>
import { computed } from 'vue';
import { formatBytes } from 'shared/helpers/FileHelper';

import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  attachments: {
    type: Array,
    default: () => [],
  },
  showHdToggle: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['removeAttachment', 'toggleHd']);

const nonRecordedAudioAttachments = computed(() => {
  return props.attachments.filter(attachment => !attachment?.isVoiceMessage);
});

const recordedAudioAttachments = computed(() =>
  props.attachments.filter(attachment => attachment.isVoiceMessage)
);

const onRemoveAttachment = itemIndex => {
  emit(
    'removeAttachment',
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

<template>
  <div class="flex flex-wrap gap-y-1 gap-x-2 overflow-auto max-h-[12.5rem]">
    <div
      v-for="(attachment, index) in nonRecordedAudioAttachments"
      :key="attachment.id"
      class="flex items-center p-1 bg-n-slate-3 gap-1 rounded-md"
      :class="showHdToggle ? 'w-[18rem]' : 'w-[15rem]'"
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
      <div class="flex-1 min-w-0">
        <span class="block h-4 text-sm font-medium truncate">
          {{ fileName(attachment.resource) }}
        </span>
      </div>
      <div class="flex-shrink-0">
        <span class="text-xs whitespace-nowrap">
          {{ formatFileSize(attachment.resource) }}
        </span>
      </div>
      <div class="flex items-center justify-center flex-shrink-0 gap-1">
        <Button
          v-if="showHdToggle && isTypeImage(attachment.resource)"
          v-tooltip.top="$t('CONVERSATION.REPLYBOX.TIP_HD_ATTACHMENT')"
          xs
          label="HD"
          :variant="attachment.isHd ? 'solid' : 'ghost'"
          :color="attachment.isHd ? 'blue' : 'slate'"
          :aria-pressed="!!attachment.isHd"
          :is-loading="!!attachment.isOptimizing"
          :disabled="!!attachment.isOptimizing"
          @click="emit('toggleHd', attachment)"
        />
        <Button
          ghost
          slate
          xs
          icon="i-lucide-x"
          @click="onRemoveAttachment(index)"
        />
      </div>
    </div>
  </div>
</template>
