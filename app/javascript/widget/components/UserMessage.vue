<script>
import UserMessageBubble from 'widget/components/UserMessageBubble.vue';
import ImageBubble from 'widget/components/ImageBubble.vue';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import FileBubble from 'widget/components/FileBubble.vue';
import { messageStamp } from 'shared/helpers/timeHelper';
import messageMixin from '../mixins/messageMixin';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';
import { mapGetters } from 'vuex';

export default {
  name: 'UserMessage',
  components: {
    UserMessageBubble,
    ImageBubble,
    FileBubble,
    FluentIcon,
  },
  mixins: [messageMixin],
  props: {
    message: {
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
    messageStatusLabel() {
      let status = '';
      if (this.isFailed) {
        status = 'Failed to send';
        if (!this.hasAttachments) status += '. Tap to retry';
      }
      return status;
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
  <div class="user-message-wrap">
    <div class="user-message">
      <div
        class="message-wrap"
        :class="{ 'in-progress': isInProgress, 'is-failed': isFailed }"
      >
        <UserMessageBubble
          v-if="showTextBubble"
          :message="message.content"
          :status="message.status"
          :widget-color="widgetColor"
          :class="{ 'blur-layer': isFailed }"
        />
        <div
          v-if="hasAttachments"
          class="chat-bubble has-attachment user"
          :class="{ 'blur-layer': isFailed }"
        >
          <div v-for="attachment in message.attachments" :key="attachment.id">
            <ImageBubble
              v-if="attachment.file_type === 'image' && !hasImageError"
              :url="attachment.data_url"
              :thumb="attachment.data_url"
              :readable-time="readableTime"
              @error="onImageLoadError"
            />
            <FileBubble
              v-else
              :url="attachment.data_url"
              :is-in-progress="isInProgress"
              :widget-color="widgetColor"
              :style="{ backgroundColor: widgetColor }"
              is-user-bubble
            />
          </div>
        </div>
        <div
          v-if="isFailed"
          class="flex justify-end align-middle px-4 py-2 text-red-700"
        >
          <button
            v-if="!hasAttachments"
            :title="$t('COMPONENTS.MESSAGE_BUBBLE.RETRY')"
            class="inline-flex justify-center items-center ml-2"
            @click="retrySendMessage"
          >
            <FluentIcon icon="arrow-clockwise" size="20" />
          </button>
          <FluentIcon v-else icon="error" size="20" type="solid" />
        </div>
      </div>
      <span v-if="isFailed" class="message-status">{{
        messageStatusLabel
      }}</span>
    </div>
  </div>
</template>
