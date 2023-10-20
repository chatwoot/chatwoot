<template>
  <div class="user-message-wrap group">
    <div class="flex gap-1 user-message">
      <button
        class="p-1.5 mb-1 rounded-full dark:text-slate-500 dark:bg-slate-900 text-slate-600 bg-slate-100 hover:text-slate-800 group-hover:opacity-100 opacity-0 sm:opacity-0"
        @click="toggleReply"
      >
        <FluentIcon icon="arrow-reply" size="12" class="flex-shrink-0" />
      </button>
      <div
        class="message-wrap"
        :class="{ 'in-progress': isInProgress, 'is-failed': isFailed }"
      >
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
            <image-bubble
              v-if="attachment.file_type === 'image' && !hasImageError"
              :url="attachment.data_url"
              :thumb="attachment.data_url"
              :readable-time="readableTime"
              @error="onImageLoadError"
            />
            <file-bubble
              v-else
              :url="attachment.data_url"
              :is-in-progress="isInProgress"
              :widget-color="widgetColor"
              is-user-bubble
            />
          </div>
        </div>
        <div
          v-if="isFailed"
          class="flex justify-end px-4 py-2 text-red-700 align-middle"
        >
          <button
            v-if="!hasAttachments"
            :title="$t('COMPONENTS.MESSAGE_BUBBLE.RETRY')"
            class="inline-flex items-center justify-center ml-2"
            @click="retrySendMessage"
          >
            <fluent-icon icon="arrow-clockwise" size="14" />
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import UserMessageBubble from 'widget/components/UserMessageBubble.vue';
import ImageBubble from 'widget/components/ImageBubble.vue';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import FileBubble from 'widget/components/FileBubble.vue';
import timeMixin from 'dashboard/mixins/time';
import messageMixin from '../mixins/messageMixin';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { mapGetters } from 'vuex';

export default {
  name: 'UserMessage',
  components: {
    UserMessageBubble,
    ImageBubble,
    FileBubble,
    FluentIcon,
  },
  mixins: [timeMixin, messageMixin],
  props: {
    message: {
      type: Object,
      default: () => {},
    },
  },
  data() {
    return {
      hasImageError: false,
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
      return this.messageStamp(createdAt);
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
  },
  watch: {
    message() {
      this.hasImageError = false;
    },
  },
  mounted() {
    this.hasImageError = false;
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
    toggleReply() {
      bus.$emit(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, this.message);
    },
  },
};
</script>
