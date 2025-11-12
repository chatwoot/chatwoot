<template>
  <div class="chat-bubble-wrap">
    <button
      class="chat-bubble agent"
      :class="$dm('bg-white', 'dark:bg-slate-50')"
      @click="onClickMessage"
    >
      <div v-if="showSender" class="row--agent-block">
        <div v-if="avatarUrl" class="flex items-start">
          <img class="h-5 rounded-[4px]" :src="avatarUrl" alt="Avatar" />
        </div>
        <!-- <thumbnail
          :src="avatarUrl"
          size="20px"
          :username="agentName"
          :status="availabilityStatus"
        /> -->
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

<script>
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
// import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import configMixin from '../mixins/configMixin';
import { isEmptyObject } from 'widget/helpers/utils';
import {
  ON_CAMPAIGN_MESSAGE_CLICK,
  ON_UNREAD_MESSAGE_CLICK,
} from '../constants/widgetBusEvents';
import darkModeMixin from 'widget/mixins/darkModeMixin';
export default {
  name: 'UnreadMessage',
  // components: { Thumbnail },
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
      return this.inboxAvatarUrl;
    },
    agentName() {
      if (this.isSenderExist(this.sender)) {
        const { available_name: availableName, name } = this.sender;
        const isAiAgent = name.toLowerCase().includes('bitespeed');
        if (isAiAgent && !this.showAiMessageIndicators) {
          return availableName;
        }
        return isAiAgent ? 'AI Support' : availableName;
      }
      if (this.useInboxAvatarForBot) {
        return this.channelConfig.websiteName;
      }
      return this.showAiMessageIndicators
        ? 'AI Support'
        : this.channelConfig.websiteName;
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
        this.$emitter.emit(ON_CAMPAIGN_MESSAGE_CLICK, this.campaignId);
      } else {
        this.$emitter.emit(ON_UNREAD_MESSAGE_CLICK);
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

.chat-bubble:hover {
  border-color: var(--widget-color) !important;
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
