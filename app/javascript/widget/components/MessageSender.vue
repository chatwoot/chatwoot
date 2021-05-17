<template>
  <div class="message-sender">
    <div class="avatar-container">
      <thumbnail
        :src="avatarUrl"
        size="28px"
        :username="agentName"
        :status="sender.availability_status"
      />
    </div>

    <div class="row--agent-block">
      <div class="name-container">
        <span class="agent--name">{{ agentName }}</span>
        <span class="company--name"> {{ companyName }}</span>
      </div>
    </div>
  </div>
</template>
<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail';
import { isEmptyObject } from 'widget/helpers/utils';
import configMixin from '../mixins/configMixin';
export default {
  name: 'MessageSender',
  components: {
    Thumbnail,
  },
  mixins: [configMixin],
  props: {
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
      // eslint-disable-next-line
      const BotImage = require('dashboard/assets/images/chatwoot_bot.png');
      const displayImage = this.useInboxAvatarForBot
        ? this.inboxAvatarUrl
        : BotImage;
      return !isEmptyObject(this.sender)
        ? this.sender.avatar_url
        : displayImage;
    },
    agentName() {
      if (!isEmptyObject(this.sender)) {
        return this.sender.available_name || this.sender.name;
      }
      return this.$t('UNREAD_VIEW.BOT');
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables';
@import '~widget/assets/scss/mixins.scss';
.message-sender {
  display: flex;
  justify-content: flex-start;
  flex-direction: row-reverse;
}
.is-widget-right .message-sender {
  flex-direction: row;
}
.avatar-container {
  width: $space-large;
  margin-bottom: $space-small;
  display: flex;
  justify-content: flex-end;
}
.is-widget-right .avatar-container {
  flex-direction: row;
  justify-content: flex-start;
}

.row--agent-block {
  background-color: $color-background-light;
  text-align: right;
  @include light-shadow;
  border-radius: $space-two;
  padding: $space-slab $space-normal $space-slab $space-normal;
  align-items: center;
  display: flex;
  text-align: left;
  padding-bottom: $space-slab;
  font-size: $font-size-small;
  margin-bottom: $space-small;
  border: 1px solid $color-border-dark;

  .agent--name {
    font-weight: $font-weight-bold;
    margin-left: $space-smaller;
  }
  .company--name {
    color: $color-light-gray;
  }
}
</style>
