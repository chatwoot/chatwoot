<script>
import { mapGetters } from 'vuex';
import configMixin from '../mixins/configMixin';
import { ON_UNREAD_MESSAGE_CLICK } from '../constants/widgetBusEvents';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import UnreadMessage from 'widget/components/UnreadMessage.vue';
import { isWidgetColorLighter } from 'shared/helpers/colorHelper';
import { emitter } from 'shared/helpers/mitt';

export default {
  name: 'Unread',
  components: {
    FluentIcon,
    UnreadMessage,
  },
  mixins: [configMixin],
  props: {
    messages: {
      type: Array,
      required: true,
    },
  },
  emits: ['close'],
  computed: {
    ...mapGetters({
      unreadMessageCount: 'conversation/getUnreadMessageCount',
      widgetColor: 'appConfig/getWidgetColor',
    }),
    sender() {
      const [firstMessage] = this.messages;
      return firstMessage.sender || {};
    },
    isBackgroundLighter() {
      return isWidgetColorLighter(this.widgetColor);
    },
  },
  methods: {
    openConversationView() {
      emitter.emit(ON_UNREAD_MESSAGE_CLICK);
    },
    closeFullView() {
      this.$emit('close');
    },
    getMessageContent(message) {
      const { attachments, content } = message;
      const hasAttachments = attachments && attachments.length;

      if (content) return content;

      if (hasAttachments) return `📑`;

      return '';
    },
  },
};
</script>

<template>
  <div class="unread-wrap" dir="ltr">
    <div class="close-unread-wrap">
      <button class="button small close-unread-button" @click="closeFullView">
        <span class="flex items-center">
          <FluentIcon class="mr-1" icon="dismiss" size="12" />
          {{ $t('UNREAD_VIEW.CLOSE_MESSAGES_BUTTON') }}
        </span>
      </button>
    </div>
    <div class="unread-messages">
      <UnreadMessage
        v-for="(message, index) in messages"
        :key="message.id"
        :message-type="message.messageType"
        :message-id="message.id"
        :show-sender="!index"
        :sender="message.sender"
        :message="getMessageContent(message)"
        :campaign-id="message.campaignId"
      />
    </div>

    <div class="open-read-view-wrap">
      <button
        v-if="unreadMessageCount"
        class="button clear-button"
        @click="openConversationView"
      >
        <span
          class="flex items-center"
          :class="{
            '!text-n-slate-12': isBackgroundLighter,
          }"
          :style="{
            color: widgetColor,
          }"
        >
          <FluentIcon class="mr-2" size="16" icon="arrow-right" />
          {{ $t('UNREAD_VIEW.VIEW_MESSAGES_BUTTON') }}
        </span>
      </button>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.unread-wrap {
  width: 100%;
  height: auto;
  max-height: 100vh;
  background: transparent;
  display: flex;
  flex-direction: column;
  flex-wrap: nowrap;
  justify-content: flex-end;
  overflow: hidden;

  .unread-messages {
    @apply pb-2;
  }

  .clear-button {
    transition: all 0.3s var(--ease-in-cubic);
    @apply bg-transparent text-n-brand border-none border-0 font-semibold text-base ml-1 py-0 pl-0 pr-2.5 hover:brightness-75 hover:translate-x-1;
  }

  .close-unread-button {
    transition: all 0.3s var(--ease-in-cubic);
    @apply bg-n-slate-3 dark:bg-n-slate-12 text-n-slate-12 dark:text-n-slate-1 hover:brightness-95 border-none border-0 font-medium text-xxs rounded-2xl mb-3;
  }
}
</style>
