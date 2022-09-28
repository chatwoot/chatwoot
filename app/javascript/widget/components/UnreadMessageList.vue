<template>
  <div class="unread-wrap">
    <div class="close-unread-wrap">
      <button class="button small close-unread-button" @click="closeFullView">
        <span class="flex items-center">
          <fluent-icon class="mr-1" icon="dismiss" size="12" />
          {{ $t('UNREAD_VIEW.CLOSE_MESSAGES_BUTTON') }}
        </span>
      </button>
    </div>
    <div class="unread-messages">
      <unread-message
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
        <span class="flex items-center">
          <fluent-icon class="mr-2" size="16" icon="arrow-right" />
          {{ $t('UNREAD_VIEW.VIEW_MESSAGES_BUTTON') }}
        </span>
      </button>
    </div>
  </div>
</template>

<script>
import { IFrameHelper } from 'widget/helpers/utils';
import { mapGetters } from 'vuex';
import configMixin from '../mixins/configMixin';
import { ON_UNREAD_MESSAGE_CLICK } from '../constants/widgetBusEvents';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import UnreadMessage from 'widget/components/UnreadMessage.vue';

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
  computed: {
    ...mapGetters({ unreadMessageCount: 'conversation/getUnreadMessageCount' }),
    sender() {
      const [firstMessage] = this.messages;
      return firstMessage.sender || {};
    },
  },
  methods: {
    openConversationView() {
      bus.$emit(ON_UNREAD_MESSAGE_CLICK);
    },
    closeFullView() {
      if (IFrameHelper.isIFrame()) {
        IFrameHelper.sendMessage({ event: 'toggleBubble' });
      }
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
<style lang="scss" scoped>
@import '~widget/assets/scss/variables';

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
    padding-bottom: $space-small;
  }

  .clear-button {
    background: transparent;
    color: $color-woot;
    padding: 0;
    border: 0;
    font-weight: $font-weight-bold;
    font-size: $font-size-medium;
    transition: all 0.3s var(--ease-in-cubic);
    margin-left: $space-smaller;
    padding-right: $space-one;

    &:hover {
      transform: translateX($space-smaller);
      color: $color-primary-dark;
    }
  }

  .close-unread-button {
    background: $color-background;
    color: $color-light-gray;
    border: 0;
    font-weight: $font-weight-medium;
    font-size: $font-size-mini;
    transition: all 0.3s var(--ease-in-cubic);
    margin-bottom: $space-slab;
    border-radius: $space-normal;

    &:hover {
      color: $color-body;
    }
  }
}
</style>
