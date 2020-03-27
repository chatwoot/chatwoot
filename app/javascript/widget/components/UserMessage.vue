<template>
  <div class="user-message">
    <div class="message-wrap" :class="{ 'in-progress': isInProgress }">
      <UserMessageBubble
        v-if="showTextBubble"
        :message="message.content"
        :status="message.status"
      />
      <div v-if="hasImage" class="chat-bubble has-attachment user">
        <image-bubble
          :url="message.attachment.data_url"
          :thumb="message.attachment.thumb_url"
          :readable-time="readableTime"
        />
      </div>
    </div>
  </div>
</template>

<script>
import UserMessageBubble from 'widget/components/UserMessageBubble';
import ImageBubble from 'widget/components/ImageBubble';
import timeMixin from 'dashboard/mixins/time';

export default {
  name: 'UserMessage',
  components: {
    UserMessageBubble,
    ImageBubble,
  },
  mixins: [timeMixin],
  props: {
    message: {
      type: Object,
      default: () => {},
    },
  },
  computed: {
    isInProgress() {
      const { status = '' } = this.message;
      return status === 'in_progress';
    },
    hasImage() {
      const { attachment = {} } = this.message;
      const { file_type: fileType } = attachment;

      return fileType === 'image';
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

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style lang="scss">
@import '~widget/assets/scss/variables.scss';
.conversation-wrap {
  .user-message {
    align-items: flex-end;
    display: flex;
    flex-direction: row;
    justify-content: flex-end;
    margin: 0 $space-smaller $space-micro auto;
    max-width: 85%;
    text-align: right;

    & + .user-message {
      margin-bottom: $space-micro;
      .chat-bubble {
        border-top-right-radius: $space-smaller;
      }
    }
    & + .agent-message {
      margin-top: $space-normal;
      margin-bottom: $space-micro;
    }
    .message-wrap {
      margin-right: $space-small;
    }

    .in-progress {
      opacity: 0.6;
    }
  }

  .has-attachment {
    padding: 0;
    overflow: hidden;
  }
}
</style>
