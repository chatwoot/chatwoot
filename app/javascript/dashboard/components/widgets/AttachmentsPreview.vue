<template>
  <div class="preview-item__wrap flex overflow-auto max-h-[12.5rem]">
    <div
      v-for="(attachment, index) in attachments"
      :key="attachment.id"
      class="preview-item flex items-center p-1 bg-slate-50 dark:bg-slate-800 gap-1 rounded-md w-[15rem] mb-1"
    >
      <div class="max-w-[4rem] flex-shrink-0 w-6 flex items-center">
        <img
          v-if="isTypeImage(attachment.resource)"
          class="image-thumb"
          :src="attachment.thumb"
        />
        <span v-else class="w-6 h-6 text-lg relative -top-px text-left">
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
        <span
          class="item overflow-hidden text-xs text-ellipsis whitespace-nowrap"
        >
          {{ formatFileSize(attachment.resource) }}
        </span>
      </div>
      <div class="flex items-center justify-center">
        <woot-button
          v-if="!isTypeAudio(attachment.resource)"
          class="remove--attachment clear secondary"
          icon="dismiss"
          @click="() => onRemoveAttachment(index)"
        />
      </div>
    </div>
  </div>
</template>
<script>
import { formatBytes } from 'shared/helpers/FileHelper';
export default {
  props: {
    attachments: {
      type: Array,
      default: () => [],
    },
    removeAttachment: {
      type: Function,
      default: () => {},
    },
  },
  methods: {
    onRemoveAttachment(index) {
      this.removeAttachment(index);
    },
    formatFileSize(file) {
      const size = file.byte_size || file.size;
      return formatBytes(size, 0);
    },
    isTypeImage(file) {
      const type = file.content_type || file.type;
      return type.includes('image');
    },
    isTypeAudio(file) {
      const type = file.content_type || file.type;
      return type.includes('audio');
    },
    fileName(file) {
      return file.filename || file.name;
    },
  },
};
</script>
<style lang="scss" scoped>
.image-thumb {
  @apply w-6 h-6 object-cover rounded-sm;
}

.file-name-wrap,
.file-size-wrap {
  @apply flex items-center py-0 px-1;

  > .item {
    @apply m-0 overflow-hidden text-xs font-medium;
  }
}

.remove--attachment {
  @apply w-6 h-6 rounded-md text-sm cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-800;
}
</style>
