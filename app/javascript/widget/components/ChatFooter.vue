<template>
  <footer
    v-if="!hideReplyBox"
    class="footer-chat shadow-sm bg-white mb-1 z-50 relative w-full"
    :class="{ 'rounded-lg': !isWidgetStyleFlat }"
  >
    <chat-input-wrap
      :on-send-message="handleSendMessage"
      :on-send-attachment="handleSendAttachment"
    />
  </footer>
  <div v-else>
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
import { mapActions, mapGetters, mapMutations } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';
import CustomButton from 'shared/components/Button';
import ChatInputWrap from 'widget/components/ChatInputWrap.vue';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { sendEmailTranscript } from 'widget/api/conversation';
import routerMixin from 'widget/mixins/routerMixin';
export default {
  components: {
    ChatInputWrap,
    CustomButton,
  },
  mixins: [routerMixin],
  props: {
    msg: {
      type: String,
      default: '',
    },
  },
  computed: {
    ...mapGetters({
      conversationAttributes: 'conversationAttributes/getConversationParams',
      widgetColor: 'appConfig/getWidgetColor',
      conversationSize: 'conversation/getConversationSize',
      currentUser: 'contacts/getCurrentUser',
      isWidgetStyleFlat: 'appConfig/isWidgetStyleFlat',
      quickRepliesOptions: 'conversation/getQuickRepliesOptions',
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
  },
  mounted() {
    const urlParams = new URLSearchParams(window.location.search);
    const referral = urlParams.get('referral');
    /* We send an empty message on mount event so the bot is aware that the conversation
    has started and can start the flow. This only happens when the url includes a referral */
    if (!this.conversationSize && referral) this.handleSendMessage('');
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
    ...mapMutations({
      setQuickRepliesOptions: 'conversation/setQuickRepliesOptions',
    }),
    async handleSendMessage(content) {
      await this.sendMessage({
        content,
      });
      // Update conversation attributes on new conversation
      if (this.conversationSize === 0) {
        this.getAttributes();
      }
      // Clear quick replies options in case the user ignores the quick replies
      if (this.quickRepliesOptions.length) {
        this.setQuickRepliesOptions([]);
      }
    },
    handleSendAttachment(attachment) {
      this.sendAttachment({ attachment });
    },
    startNewConversation() {
      this.clearConversations();
      this.clearConversationAttributes();

      // To create a new conversation, we are redirecting
      // the user to pre-chat with contact fields disabled
      // Pass disableContactFields params to the route
      // This would disable the contact fields in the pre-chat form
      this.replaceRoute('prechat-form', { disableContactFields: true });
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

.footer-chat {
  max-width: $break-point-tablet;
  margin: 0 auto;
}

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
