<script>
import UserMessageBubble from 'widget/components/UserMessageBubble.vue';
import MessageReplyButton from 'widget/components/MessageReplyButton.vue';
import ImageBubble from 'widget/components/ImageBubble.vue';
import VideoBubble from 'widget/components/VideoBubble.vue';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import FileBubble from 'widget/components/FileBubble.vue';
import { messageStamp } from 'shared/helpers/timeHelper';
import messageMixin from '../mixins/messageMixin';
import ReplyToChip from 'widget/components/ReplyToChip.vue';
import DragWrapper from 'widget/components/DragWrapper.vue';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';
import { mapGetters } from 'vuex';

export default {
  name: 'UserMessage',
  components: {
    UserMessageBubble,
    MessageReplyButton,
    ImageBubble,
    VideoBubble,
    FileBubble,
    FluentIcon,
    ReplyToChip,
    DragWrapper,
  },
  mixins: [messageMixin],
  props: {
    message: {
      type: Object,
      default: () => {},
    },
    replyTo: {
      type: Object,
      default: () => {},
    },
  },
  data() {
    return {
      hasImageError: false,
      hasVideoError: false,
    };
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
      return messageStamp(createdAt);
    },
    isFailed() {
      const { status = '' } = this.message;
      return status === 'failed';
    },
    errorMessage() {
      const { meta } = this.message;
      return meta
        ? meta.error
        : this.$t('COMPONENTS.MESSAGE_BUBBLE.ERROR_MESSAGE');
    },
    hasReplyTo() {
      return this.replyTo && (this.replyTo.content || this.replyTo.attachments);
    },
  },
  watch: {
    message() {
      this.hasImageError = false;
      this.hasVideoError = false;
    },
  },
  mounted() {
    this.hasImageError = false;
    this.hasVideoError = false;
  },
  methods: {
    async retrySendMessage() {
      await this.$store.dispatch(
        'conversation/sendMessageWithData',
        this.message
      );
    },
    onImageLoadError() {
      this.hasImageError = true;
    },
    onVideoLoadError() {
      this.hasVideoError = true;
    },
    toggleReply() {
      emitter.emit(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, this.message);
    },
  },
};
</script>

<template>
  <div class="user-message-wrap group">
    <div class="flex gap-1 user-message">
      <div
        class="message-wrap"
        :class="{ 'in-progress': isInProgress, 'is-failed': isFailed }"
      >
        <div v-if="hasReplyTo" class="flex justify-end mt-2 mb-1 text-xs">
          <ReplyToChip :reply-to="replyTo" />
        </div>
        <div class="flex justify-end gap-1">
          <div class="flex flex-col justify-end">
            <MessageReplyButton
              v-if="!isInProgress && !isFailed"
              class="transition-opacity delay-75 opacity-0 group-hover:opacity-100 sm:opacity-0"
              @click="toggleReply"
            />
          </div>
          <DragWrapper direction="left" @dragged="toggleReply">
            <UserMessageBubble
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
              <div
                v-for="attachment in message.attachments"
                :key="attachment.id"
              >
                <ImageBubble
                  v-if="attachment.file_type === 'image' && !hasImageError"
                  :url="attachment.data_url"
                  :thumb="attachment.data_url"
                  :readable-time="readableTime"
                  @error="onImageLoadError"
                />

                <VideoBubble
                  v-if="attachment.file_type === 'video' && !hasVideoError"
                  :url="attachment.data_url"
                  :readable-time="readableTime"
                  @error="onVideoLoadError"
                />

                <FileBubble
                  v-else
                  :url="attachment.data_url"
                  :is-in-progress="isInProgress"
                  :widget-color="widgetColor"
                  is-user-bubble
                />
              </div>
            </div>
          </DragWrapper>
        </div>
        <div
          v-if="isFailed"
          class="flex justify-end px-4 py-2 text-n-ruby-9 align-middle"
        >
          <button
            v-if="!hasAttachments"
            :title="$t('COMPONENTS.MESSAGE_BUBBLE.RETRY')"
            class="inline-flex items-center justify-center ltr:ml-2 rtl:mr-2"
            @click="retrySendMessage"
          >
            <FluentIcon icon="arrow-clockwise" size="14" />
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
