<template>
  <div
    class="reply-editor bg-slate-50 rounded-md py-1 pl-2 pr-1 text-xs tracking-wide mt-2 flex items-center gap-1.5 -mx-2 cursor-pointer"
    @click="$emit('navigate-to-message', messageId)"
  >
    <fluent-icon class="flex-shrink-0 icon" icon="arrow-reply" icon-size="14" />
    <div class="flex-grow overflow-hidden text-ellipsis">
      {{ $t('CONVERSATION.REPLYBOX.REPLYING_TO') }} {{ cleanedContent }}.
    </div>
    <woot-button
      v-tooltip="$t('CONVERSATION.REPLYBOX.DISMISS_REPLY')"
      color-scheme="secondary"
      icon="dismiss"
      variant="clear"
      size="tiny"
      class="flex-shrink-0"
      @click.stop="$emit('dismiss')"
    />
  </div>
</template>

<script>
import { ATTACHMENT_ICONS } from 'shared/constants/messages';
import { extractTextFromMarkdown } from 'dashboard/helper/editorHelper';

export default {
  props: {
    messageId: {
      type: Number,
      required: true,
    },
    content: {
      type: String,
      default: '',
    },
    attachments: {
      type: Array,
      default: () => [],
    },
  },
  computed: {
    cleanedContent() {
      return extractTextFromMarkdown(this.content);
    },
    attachmentIcon() {
      return ATTACHMENT_ICONS[this.attachments[0]?.file_type];
    },
    attachmentLabel() {
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

<style lang="scss">
// TODO: Remove this
// override for dashboard/assets/scss/widgets/_reply-box.scss
.reply-editor {
  .icon {
    margin-right: 0px !important;
  }
}
</style>
