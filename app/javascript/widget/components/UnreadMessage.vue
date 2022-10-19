<template>
  <div class="chat-bubble-wrap">
    <button
      class="chat-bubble agent"
      :class="$dm('bg-white', 'dark:bg-slate-50')"
      @click="onClickMessage"
    >
      <div v-if="showSender" class="row--agent-block">
        <thumbnail
          :src="avatarUrl"
          size="20px"
          :username="agentName"
          :status="availabilityStatus"
        />
        <span class="agent--name">{{ agentName }}</span>
        <span class="company--name"> {{ companyName }}</span>
      </div>
      <div
        v-dompurify-html="formatMessage(message, false)"
        class="message-content"
      />
    </button>
  </div>
</template>

<script>
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import Thumbnail from 'dashboard/components/widgets/Thumbnail';
import configMixin from '../mixins/configMixin';
import { isEmptyObject } from 'widget/helpers/utils';
import {
  ON_CAMPAIGN_MESSAGE_CLICK,
  ON_UNREAD_MESSAGE_CLICK,
} from '../constants/widgetBusEvents';
import darkModeMixin from 'widget/mixins/darkModeMixin';
export default {
  name: 'UnreadMessage',
  components: { Thumbnail },
  mixins: [messageFormatterMixin, configMixin, darkModeMixin],
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
  computed: {
    companyName() {
      return `${this.$t('UNREAD_VIEW.COMPANY_FROM')} ${
        this.channelConfig.websiteName
      }`;
    },
    avatarUrl() {
      // eslint-disable-next-line
      const BotImage = require('dashboard/assets/images/chatwoot_bot.png');
      const displayImage = this.useInboxAvatarForBot
        ? this.inboxAvatarUrl
        : BotImage;
      if (this.isSenderExist(this.sender)) {
        const { avatar_url: avatarUrl } = this.sender;
        return avatarUrl;
      }
      return displayImage;
    },
    agentName() {
      if (this.isSenderExist(this.sender)) {
        const { available_name: availableName, name } = this.sender;
        return availableName || name;
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
        bus.$emit(ON_CAMPAIGN_MESSAGE_CLICK, this.campaignId);
      } else {
        bus.$emit(ON_UNREAD_MESSAGE_CLICK);
      }
    },
  },
};
</script>
<style lang="scss" scoped>
@import '~widget/assets/scss/variables.scss';
.chat-bubble {
  max-width: 85%;
  padding: $space-normal;
  cursor: pointer;
}

.row--agent-block {
  align-items: center;
  display: flex;
  text-align: left;
  padding-bottom: $space-small;
  font-size: $font-size-small;
  .agent--name {
    font-weight: $font-weight-medium;
    margin-left: $space-smaller;
  }
  .company--name {
    color: $color-light-gray;
    margin-left: $space-smaller;
  }
}
</style>
