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
import { mapGetters } from 'vuex';

export default {
  name: 'UserMessage',
  components: {
    UserMessageBubble,
    ImageBubble,
    FileBubble,
  },
  mixins: [timeMixin],
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
    hasAttachments() {
      return !!(
        this.message.attachments && this.message.attachments.length > 0
      );
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

    .message-wrap {
      margin-right: $space-small;
      max-width: 100%;
    }

    .in-progress {
      opacity: 0.6;
    }
  }

  .has-attachment {
    padding: 0;
    overflow: hidden;
  }

  .user.has-attachment {
    .icon-wrap {
      color: $color-white;
    }

    .download {
      color: $color-white;
    }
  }

  .user-message-wrap {
    + .user-message-wrap {
      margin-top: $space-micro;

      .user-message .chat-bubble {
        border-top-right-radius: $space-smaller;
      }
    }

    + .agent-message-wrap {
      margin-top: $space-normal;
    }
  }
}
</style>
