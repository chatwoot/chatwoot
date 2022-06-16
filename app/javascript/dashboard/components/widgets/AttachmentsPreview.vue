<template>
  <div class="preview-item__wrap">
    <div
      v-for="(attachment, index) in attachments"
      :key="attachment.id"
      class="preview-item"
    >
      <div class="thumb-wrap">
        <img
          v-if="isTypeImage(attachment.resource)"
          class="image-thumb"
          :src="attachment.thumb"
        />
        <span v-else class="attachment-thumb"> 📄 </span>
      </div>
      <div class="file-name-wrap">
        <span class="item">
          {{ fileName(attachment.resource) }}
        </span>
      </div>
      <div class="file-size-wrap">
        <span class="item text-truncate">
          {{ formatFileSize(attachment.resource) }}
        </span>
      </div>
      <div class="remove-file-wrap">
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
.preview-item__wrap {
  display: flex;
  flex-direction: column;
  overflow: auto;
  margin-top: var(--space-normal);
  max-height: 20rem;
}

.preview-item {
  display: flex;
  padding: var(--space-slab) 0 0;
  background: var(--color-background-light);
  background: var(--b-50);
  border-radius: var(--border-radius-normal);
  width: 24rem;
  padding: var(--space-smaller);
  margin-bottom: var(--space-one);
}

.thumb-wrap {
  max-width: var(--space-jumbo);
  flex-shrink: 0;
  width: var(--space-medium);
  display: flex;
  align-items: center;
}

.image-thumb {
  width: var(--space-medium);
  height: var(--space-medium);
  object-fit: cover;
  border-radius: var(--border-radius-small);
}

.attachment-thumb {
  width: var(--space-medium);
  height: var(--space-medium);
  font-size: var(--font-size-medium);
  text-align: center;
  position: relative;
  top: -1px;
  text-align: left;
}

.file-name-wrap,
.file-size-wrap {
  display: flex;
  align-items: center;
  padding: 0 var(--space-smaller);

  > .item {
    margin: 0;
    overflow: hidden;
    font-size: var(--font-size-mini);
    font-weight: var(--font-weight-medium);
  }
}

.preview-header {
  padding: var(--space-slab) var(--space-slab) 0 var(--space-slab);
}

.file-name-wrap {
  max-width: 60%;
  min-width: 50%;
  overflow: hidden;
  text-overflow: ellipsis;
  margin-left: var(--space-small);

  .item {
    height: var(--space-normal);
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
}

.file-size-wrap {
  width: 30%;
  justify-content: center;
}

.remove-file-wrap {
  display: flex;
  align-items: center;
  justify-content: center;
}

.remove--attachment {
  width: var(--space-medium);
  height: var(--space-medium);
  border-radius: var(--space-medium);
  font-size: var(--font-size-small);
  cursor: pointer;

  &:hover {
    background: var(--color-background);
  }
}
</style>
