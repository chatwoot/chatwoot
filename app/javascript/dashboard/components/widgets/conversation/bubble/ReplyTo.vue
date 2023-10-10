<template>
  <div
    class="p-2 -mx-2 rounded-md bg-woot-600 min-w-[15rem] mb-2 cursor-pointer"
    @click="$emit('click')"
  >
    <div v-if="content" class="line-clamp-3">
      {{ cleanedContent }}
    </div>
    <div v-else-if="hasAttachments" class="line-clamp-3">
      {{ attachmentLabel }}
    </div>
    <template v-else> {{ defaultEmptyMessage }} </template>
  </div>
</template>

<script>
import { extractTextFromMarkdown } from 'dashboard/helper/editorHelper';

export default {
  name: 'ReplyTo',
  props: {
    content: {
      type: String,
      default: '',
    },
    attachments: {
      type: Array,
      default: () => [],
    },
    defaultEmptyMessage: {
      type: String,
      required: true,
    },
  },
  computed: {
    cleanedContent() {
      return extractTextFromMarkdown(this.content);
    },
    hasAttachments() {
      return this.attachments.length > 0;
    },
    attachmentLabel() {
      if (!this.attachments.length) return null;

      const firstFileName = this.attachments[0].data_url?.split('/').pop();

      if (this.attachments.length > 1) {
        if (firstFileName) {
          return this.$t(
            'CONVERSATION.REPLY_TO_ATTACHMENT.FILE_PLUS_MULTIPLE',
            {
              first: firstFileName,
              count: (this.attachments.length - 1).toLocaleString(),
            }
          );
        }

        return this.$t('CONVERSATION.REPLY_TO_ATTACHMENT.COUNT', {
          count: this.attachments.length.toLocaleString(),
        });
      }

      return (
        firstFileName ?? this.$t('CONVERSATION.REPLY_TO_ATTACHMENT.ATTACHMENT')
      );
    },
  },
};
</script>
