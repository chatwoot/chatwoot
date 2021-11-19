<template>
  <div class="user-message-wrap">
    <div class="user-message">
      <div class="message-wrap" :class="{ 'in-progress': isInProgress }">
        <user-message-bubble
          v-if="showTextBubble"
          :message="message.content"
          :status="message.status"
          :widget-color="widgetColor"
        />
        <div
          v-if="hasAttachments"
          class="chat-bubble has-attachment user"
          :style="{ backgroundColor: widgetColor }"
        >
          <div v-for="attachment in message.attachments" :key="attachment.id">
            <file-bubble
              v-if="attachment.file_type !== 'image'"
              :url="attachment.data_url"
              :is-in-progress="isInProgress"
            />
            <image-bubble
              v-else
              :url="attachment.data_url"
              :thumb="attachment.thumb_url"
              :readable-time="readableTime"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import UserMessageBubble from 'widget/components/UserMessageBubble';
import ImageBubble from 'widget/components/ImageBubble';
import FileBubble from 'widget/components/FileBubble';
import timeMixin from 'dashboard/mixins/time';
import messageMixin from '../mixins/messageMixin';
import { mapGetters } from 'vuex';

export default {
  name: 'UserMessage',
  components: {
    UserMessageBubble,
    ImageBubble,
    FileBubble,
  },
  mixins: [timeMixin, messageMixin],
  props: {
    message: {
      type: Object,
      default: () => {},
    },
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),

    isInProgress() {
      const { status = '' } = this.message;
      return status === 'in_progress';
    },
    showTextBubble() {
      const { message } = this;
      return !!message.content;
    },
    readableTime() {
      const { created_at: createdAt = '' } = this.message;
      return this.messageStamp(createdAt);
    },
  },
};
</script>
