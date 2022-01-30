<template>
  <div>
    <div
      v-for="(attachment, index) in attachments"
      :key="attachment.id"
      class="preview-item"
    >
      <div class="thumb-wrap">
        <img
          v-if="isTypeImage(attachment.resource.content_type)"
          class="image-thumb"
          :src="attachment.thumb"
        />
        <span v-else class="attachment-thumb"> 📄 </span>
      </div>
      <div class="file-name-wrap">
        <span class="item">
          {{ attachment.resource.filename }}
        </span>
      </div>
      <div class="file-size-wrap">
        <span class="item">
          {{ formatFileSize(attachment.resource.byte_size) }}
        </span>
      </div>
      <div class="remove-file-wrap">
        <woot-button
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
    formatFileSize(size) {
      return formatBytes(size, 0);
    },
    isTypeImage(type) {
      return type.includes('image');
    },
  },
};
</script>
<style lang="scss" scoped>
.preview-item {
  display: flex;
  padding: var(--space-slab) 0 0;
  background: var(--color-background-light);
  background: var(--b-50);
  border-radius: var(--border-radius-normal);
  width: fit-content;
  padding: var(--space-smaller);
  margin-top: var(--space-normal);
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
    font-size: var(--font-size-mini);
    font-weight: var(--font-weight-medium);
  }
}

.preview-header {
  padding: var(--space-slab) var(--space-slab) 0 var(--space-slab);
}

.file-name-wrap {
  max-width: 50%;
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
