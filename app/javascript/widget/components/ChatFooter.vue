<template>
  <footer
    v-if="!hideReplyBox"
    class="relative z-50 mb-1"
    :class="{
      'rounded-lg': !isWidgetStyleFlat,
      'pt-2.5 shadow-[0px_-20px_20px_1px_rgba(0,_0,_0,_0.05)] rounded-t-none':
        hasReplyTo,
    }"
  >
    <div
      v-if="inReplyTo && inReplyTo.content"
      class="mb-2.5 rounded-[7px] dark:bg-slate-900 dark:text-slate-100 bg-slate-100 px-2 py-1.5 text-sm text-slate-700 flex items-center gap-2"
    >
      <div class="flex-grow truncate">
        <strong>Replying to:</strong> {{ inReplyTo.content }}
      </div>
      <button
        class="items-end flex-shrink-0 p-1 rounded-md hover:bg-slate-200 dark:hover:bg-slate-800"
        @click="inReplyTo = null"
      >
        <fluent-icon icon="dismiss" size="12" />
      </button>
    </div>
    <chat-input-wrap
      class="bg-white shadow-sm"
      :on-send-message="handleSendMessage"
      :on-send-attachment="handleSendAttachment"
    />
  </footer>
  <div v-else class="bg-white shadow-sm">
    <custom-button
      class="font-medium"
      block
      :bg-color="widgetColor"
      :text-color="textColor"
      @click="startNewConversation"
    >
      {{ $t('START_NEW_CONVERSATION') }}
    </custom-button>
    <custom-button
      v-if="showEmailTranscriptButton"
      type="clear"
      class="font-normal"
      @click="sendTranscript"
    >
      {{ $t('EMAIL_TRANSCRIPT.BUTTON_TEXT') }}
    </custom-button>
  </div>
</template>

<script>
import { mapActions, mapGetters } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';
import CustomButton from 'shared/components/Button.vue';
import ChatInputWrap from 'widget/components/ChatInputWrap.vue';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { sendEmailTranscript } from 'widget/api/conversation';
import routerMixin from 'widget/mixins/routerMixin';
import { IFrameHelper } from '../helpers/utils';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import { CHATWOOT_ON_START_CONVERSATION } from '../constants/sdkEvents';

export default {
  components: {
    ChatInputWrap,
    CustomButton,
    FluentIcon,
  },
  mixins: [routerMixin],
  props: {
    msg: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      inReplyTo: null,
    };
  },
  computed: {
    ...mapGetters({
      conversationAttributes: 'conversationAttributes/getConversationParams',
      widgetColor: 'appConfig/getWidgetColor',
      conversationSize: 'conversation/getConversationSize',
      currentUser: 'contacts/getCurrentUser',
      isWidgetStyleFlat: 'appConfig/isWidgetStyleFlat',
    }),
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
    hideReplyBox() {
      const { allowMessagesAfterResolved } = window.chatwootWebChannel;
      const { status } = this.conversationAttributes;
      return !allowMessagesAfterResolved && status === 'resolved';
    },
    showEmailTranscriptButton() {
      return this.currentUser && this.currentUser.email;
    },
    hasReplyTo() {
      return (
        this.inReplyTo && (this.inReplyTo.content || this.inReplyTo.attachments)
      );
    },
  },
  mounted() {
    bus.$on(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, this.toggleReplyTo);
  },
  methods: {
    ...mapActions('conversation', [
      'sendMessage',
      'sendAttachment',
      'clearConversations',
    ]),
    ...mapActions('conversationAttributes', [
      'getAttributes',
      'clearConversationAttributes',
    ]),
    async handleSendMessage(content) {
      await this.sendMessage({
        content,
        replyTo: this.inReplyTo ? this.inReplyTo.id : null,
      });
      // reset replyTo message after sending
      this.inReplyTo = null;
      // Update conversation attributes on new conversation
      if (this.conversationSize === 0) {
        this.getAttributes();
      }
    },
    handleSendAttachment(attachment) {
      this.sendAttachment({ attachment });
    },
    startNewConversation() {
      this.clearConversations();
      this.clearConversationAttributes();
      this.replaceRoute('prechat-form');
      IFrameHelper.sendMessage({
        event: 'onEvent',
        eventIdentifier: CHATWOOT_ON_START_CONVERSATION,
        data: { hasConversation: true },
      });
    },
    toggleReplyTo(message) {
      this.inReplyTo = message;
    },
    async sendTranscript() {
      const { email } = this.currentUser;
      if (email) {
        try {
          await sendEmailTranscript({
            email,
          });
          window.bus.$emit(BUS_EVENTS.SHOW_ALERT, {
            message: this.$t('EMAIL_TRANSCRIPT.SEND_EMAIL_SUCCESS'),
            type: 'success',
          });
        } catch (error) {
          window.bus.$emit(BUS_EVENTS.SHOW_ALERT, {
            message: this.$t('EMAIL_TRANSCRIPT.SEND_EMAIL_ERROR'),
          });
        }
      }
    },
  },
};
</script>
<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.branding {
  align-items: center;
  color: $color-body;
  display: flex;
  font-size: $font-size-default;
  justify-content: center;
  padding: $space-one;
  text-align: center;
  text-decoration: none;

  img {
    margin-right: $space-small;
    max-width: $space-two;
  }
}
</style>
