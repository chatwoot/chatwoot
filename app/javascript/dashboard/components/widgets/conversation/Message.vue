<template>
  <li v-if="hasAttachments || data.content" :class="alignBubble">
    <div :class="wrapClass">
      <p v-tooltip.top-start="sentByMessage" :class="bubbleClass">
        <bubble-text
          v-if="data.content"
          :message="message"
          :is-email="isEmailContentType"
          :readable-time="readableTime"
        />
        <span v-if="hasAttachments">
          <span v-for="attachment in data.attachments" :key="attachment.id">
            <bubble-image
              v-if="attachment.file_type === 'image'"
              :url="attachment.data_url"
              :readable-time="readableTime"
            />
            <bubble-file
              v-if="attachment.file_type !== 'image'"
              :url="attachment.data_url"
              :readable-time="readableTime"
            />
          </span>
        </span>
        <bubble-actions
          :is-email="isEmailContentType"
          :readable-time="readableTime"
          :is-private="data.private"
        />
      </p>
    </div>
  </li>
</template>
<script>
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import getEmojiSVG from '../emoji/utils';
import timeMixin from '../../../mixins/time';
import BubbleText from './bubble/Text';
import BubbleImage from './bubble/Image';
import BubbleFile from './bubble/File';
import contentTypeMixin from 'shared/mixins/contentTypeMixin';
import BubbleActions from './bubble/Actions';
export default {
  components: {
    BubbleActions,
    BubbleText,
    BubbleImage,
    BubbleFile,
  },
  mixins: [timeMixin, messageFormatterMixin, contentTypeMixin],
  props: {
    data: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isHovered: false,
    };
  },
  computed: {
    message() {
      return this.formatMessage(this.data.content);
    },
    contentType() {
      const {
        data: { content_type: contentType },
      } = this;
      return contentType;
    },
    alignBubble() {
      return !this.data.message_type ? 'left' : 'right';
    },
    readableTime() {
      return this.messageStamp(this.data.created_at);
    },
    isBubble() {
      return [0, 1, 3].includes(this.data.message_type);
    },
    hasAttachments() {
      return !!(this.data.attachments && this.data.attachments.length > 0);
    },
    hasImageAttachment() {
      if (this.hasAttachments && this.data.attachments.length > 0) {
        const { attachments = [{}] } = this.data;
        const { file_type: fileType } = attachments[0];
        return fileType === 'image';
      }
      return false;
    },
    sentByMessage() {
      const { sender } = this.data;

      return this.data.message_type === 1 && !this.isHovered && sender
        ? {
            content: `Sent by: ${sender.available_name || sender.name}`,
            classes: 'top',
          }
        : false;
    },
    wrapClass() {
      return {
        wrap: this.isBubble,
        'activity-wrap': !this.isBubble,
      };
    },
    bubbleClass() {
      return {
        bubble: this.isBubble,
        'is-private': this.data.private,
        'is-image': this.hasImageAttachment,
      };
    },
  },
  methods: {
    getEmojiSVG,
  },
};
</script>
<style lang="scss">
.wrap > .is-image.bubble {
  padding: 0;
  overflow: hidden;

  .image {
    max-width: 32rem;
    padding: 0;
  }
}
</style>
