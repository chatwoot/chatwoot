<script>
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import TranslatingContent from 'widget/components/TranslatingContent.vue';
import configMixin from '../mixins/configMixin';
import { isEmptyObject } from 'widget/helpers/utils';
import {
  ON_CAMPAIGN_MESSAGE_CLICK,
  ON_UNREAD_MESSAGE_CLICK,
} from '../constants/widgetBusEvents';
import { emitter } from 'shared/helpers/mitt';

export default {
  name: 'UnreadMessage',
  components: { Avatar, TranslatingContent },
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
    translating: {
      type: Boolean,
      default: false,
    },
    translated: {
      type: Boolean,
      default: false,
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
        const { available_name: availableName, name } = this.sender;
        return availableName || name || '';
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
      <div
        v-if="showSender"
        class="row--agent-block flex items-center pb-2 text-xs text-start"
      >
        <Avatar
          :src="avatarUrl"
          :size="16"
          :name="agentName"
          :status="availabilityStatus"
          rounded-full
        />
        <span class="ms-1">
          <span class="agent--name font-medium">{{ agentName }}</span>
          <span class="company--name ms-1 text-n-slate-11 dark:text-n-slate-10">
            {{ companyName }}
          </span>
        </span>
      </div>
      <TranslatingContent :translating="translating" :translated="translated">
        <div
          v-dompurify-html="formatMessage(message, false)"
          class="message-content"
        />
      </TranslatingContent>
    </button>
  </div>
</template>

<style lang="scss" scoped>
.chat-bubble {
  @apply max-w-[85%] cursor-pointer p-4;
}
</style>
