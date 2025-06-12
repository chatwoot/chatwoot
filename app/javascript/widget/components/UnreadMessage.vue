<script>
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import configMixin from '../mixins/configMixin';
import { isEmptyObject } from 'widget/helpers/utils';
import {
  ON_CAMPAIGN_MESSAGE_CLICK,
  ON_UNREAD_MESSAGE_CLICK,
} from '../constants/widgetBusEvents';
import { emitter } from 'shared/helpers/mitt';

export default {
  name: 'UnreadMessage',
  components: { Thumbnail },
  mixins: [configMixin],
  props: {
    message: {
      type: String,
      default: '',
    },
    showSender: {
      type: Boolean,
      default: false,
    },
    sender: {
      type: Object,
      default: () => {},
    },
    campaignId: {
      type: Number,
      default: null,
    },
  },
  setup() {
    const { formatMessage, getPlainText, truncateMessage, highlightContent } =
      useMessageFormatter();
    return {
      formatMessage,
      getPlainText,
      truncateMessage,
      highlightContent,
    };
  },
  computed: {
    companyName() {
      return `${this.$t('UNREAD_VIEW.COMPANY_FROM')} ${
        this.channelConfig.websiteName
      }`;
    },
    avatarUrl() {
      // eslint-disable-next-line
      const displayImage = this.useInboxAvatarForBot
        ? this.inboxAvatarUrl
        : '/assets/images/chatwoot_bot.png';
      if (this.isSenderExist(this.sender)) {
        const { avatar_url: avatarUrl } = this.sender;
        return avatarUrl;
      }
      return displayImage;
    },
    agentName() {
      if (this.isSenderExist(this.sender)) {
        const { available_name: availableName } = this.sender;
        return availableName;
      }
      if (this.useInboxAvatarForBot) {
        return this.channelConfig.websiteName;
      }
      return this.$t('UNREAD_VIEW.BOT');
    },
    availabilityStatus() {
      if (this.isSenderExist(this.sender)) {
        const { availability_status: availabilityStatus } = this.sender;
        return availabilityStatus;
      }
      return null;
    },
  },
  methods: {
    isSenderExist(sender) {
      return sender && !isEmptyObject(sender);
    },
    onClickMessage() {
      if (this.campaignId) {
        emitter.emit(ON_CAMPAIGN_MESSAGE_CLICK, this.campaignId);
      } else {
        emitter.emit(ON_UNREAD_MESSAGE_CLICK);
      }
    },
  },
};
</script>

<template>
  <div class="chat-bubble-wrap">
    <button class="chat-bubble agent bg-white" @click="onClickMessage">
      <div v-if="showSender" class="row--agent-block">
        <Thumbnail
          :src="avatarUrl"
          size="20px"
          :username="agentName"
          :status="availabilityStatus"
        />
        <span v-dompurify-html="agentName" class="agent--name" />
        <span v-dompurify-html="companyName" class="company--name" />
      </div>
      <div
        v-dompurify-html="formatMessage(message, false)"
        class="message-content"
      />
    </button>
  </div>
</template>

<style lang="scss" scoped>
.chat-bubble {
  @apply max-w-[85%] cursor-pointer p-4;
}

.row--agent-block {
  @apply items-center flex text-left pb-2 text-xs;

  .agent--name {
    @apply font-medium ml-1;
  }

  .company--name {
    @apply text-n-slate-11 dark:text-n-slate-10 ml-1;
  }
}
</style>
