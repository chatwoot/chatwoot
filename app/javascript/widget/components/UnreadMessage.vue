<template>
  <div class="chat-bubble-wrap">
    <div class="chat-bubble agent">
      <div v-if="showSender" class="row--agent-block">
        <thumbnail
          :src="avatarUrl"
          size="20px"
          :username="agentName"
          :status="sender.availability_status"
        />
        <span class="agent--name">{{ agentName }}</span>
        <span class="company--name"> {{ companyName }}</span>
      </div>
      <div class="message-content" v-html="formatMessage(message, false)"></div>
    </div>
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
  },
  computed: {
    companyName() {
      return `${this.$t('UNREAD_VIEW.COMPANY_FROM')} ${
        this.channelConfig.websiteName
      }`;
    },
    avatarUrl() {
      const { avatar_url: avatarUrl } = this.sender;
      // eslint-disable-next-line
      const BotImage = require('dashboard/assets/images/chatwoot_bot.png');
      const displayImage = this.useInboxAvatarForBot
        ? this.inboxAvatarUrl
        : BotImage;
      return !isEmptyObject(this.sender) ? avatarUrl : displayImage;
    },
    agentName() {
      const { available_name: availableName, name } = this.sender;
      if (!isEmptyObject(this.sender)) {
        return availableName || name;
      }
      return this.$t('UNREAD_VIEW.BOT');
    },
  },
};
</script>

<style lang="scss">
@import '~widget/assets/scss/variables.scss';
.chat-bubble {
  max-width: 85%;
  padding: $space-normal;
}
</style>
<style lang="scss" scoped>
@import '~widget/assets/scss/variables.scss';
.row--agent-block {
  align-items: center;
  display: flex;
  text-align: left;
  padding-bottom: $space-small;
  font-size: $font-size-small;
  .agent--name {
    font-weight: $font-weight-bold;
    margin-left: $space-smaller;
  }
  .company--name {
    color: $color-light-gray;
    margin-left: $space-smaller;
  }
}
</style>
