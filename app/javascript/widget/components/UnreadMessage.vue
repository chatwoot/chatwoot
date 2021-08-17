<template>
  <div class="chat-bubble-wrap">
    <button class="chat-bubble agent" @click="onClickMessage">
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
      <div class="message-content" v-html="formatMessage(message, false)"></div>
    </button>
  </div>
</template>

<script>
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import Thumbnail from 'dashboard/components/widgets/Thumbnail';
import configMixin from '../mixins/configMixin';
import { isEmptyObject } from 'widget/helpers/utils';
export default {
  name: 'UnreadMessage',
  components: { Thumbnail },
  mixins: [messageFormatterMixin, configMixin],
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
        bus.$emit('on-campaign-view-clicked', this.campaignId);
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
