<template>
  <div class="chat-bubble-wrap">
    <div class="chat-bubble agent">
      <div v-if="showSender" class="row--agent-block">
        <thumbnail
          :src="sender.avatar_url"
          size="24px"
          :username="sender.available_name"
          :status="sender.availability_status"
        />
        <span class="agent--name">{{ sender.available_name }}</span>
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
export default {
  name: 'AgentMessageBubble',
  components: {
    Thumbnail,
  },
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
  },
};
</script>

<style lang="scss">
@import '~widget/assets/scss/variables.scss';

.chat-bubble {
  &.agent {
    background: $color-white;
    border-bottom-left-radius: $space-smaller;
    color: $color-body;

    .link {
      word-break: break-word;
      color: $color-woot;
    }
  }
}
</style>
<style lang="scss" scoped>
@import '~widget/assets/scss/variables.scss';

.chat-bubble {
  max-width: 85%;
  padding: $space-normal $space-normal;
}
.chat-bubble .message-content::v-deep pre {
  background: $color-primary-light;
  color: $color-body;
  overflow: scroll;
  padding: $space-smaller;
}

.row--agent-block {
  align-items: center;
  display: flex;
  text-align: left;
  padding-bottom: $space-slab;
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
