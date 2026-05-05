<script>
import { mapActions, mapGetters } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';
import CustomButton from 'shared/components/Button.vue';
import FooterReplyTo from 'widget/components/FooterReplyTo.vue';
import ChatInputWrap from 'widget/components/ChatInputWrap.vue';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { CONVERSATION_STATUS } from 'shared/constants/messages';
import { sendEmailTranscript } from 'widget/api/conversation';
import { useRouter } from 'vue-router';
import { IFrameHelper } from '../helpers/utils';
import { CHATWOOT_ON_START_CONVERSATION } from '../constants/sdkEvents';
import { emitter } from 'shared/helpers/mitt';

const CAPTAIN_HANDOFF_REPLY_THRESHOLD = 5;

export default {
  components: {
    ChatInputWrap,
    CustomButton,
    FooterReplyTo,
  },
  setup() {
    const router = useRouter();
    return { router };
  },
  data() {
    return {
      inReplyTo: null,
      isRequestingHandoff: false,
    };
  },
  computed: {
    ...mapGetters({
      conversationAttributes: 'conversationAttributes/getConversationParams',
      widgetColor: 'appConfig/getWidgetColor',
      conversationSize: 'conversation/getConversationSize',
      captainReplyCount: 'conversation/getCaptainReplyCount',
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
      return this.hasEmail;
    },
    showCaptainHandoffButton() {
      return (
        this.conversationAttributes.status === CONVERSATION_STATUS.PENDING &&
        this.captainReplyCount >= CAPTAIN_HANDOFF_REPLY_THRESHOLD
      );
    },
    hasEmail() {
      return this.currentUser && this.currentUser.has_email;
    },
    hasReplyTo() {
      return (
        this.inReplyTo && (this.inReplyTo.content || this.inReplyTo.attachments)
      );
    },
  },
  mounted() {
    emitter.on(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, this.toggleReplyTo);
  },
  methods: {
    ...mapActions('conversation', [
      'sendMessage',
      'sendAttachment',
      'requestHandoff',
    ]),
    ...mapActions('conversationAttributes', ['getAttributes']),
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
    async handleSendAttachment(attachment) {
      await this.sendAttachment({
        attachment,
        replyTo: this.inReplyTo ? this.inReplyTo.id : null,
      });
      this.inReplyTo = null;
    },
    startNewConversation() {
      this.router.replace({ name: 'prechat-form' });
      IFrameHelper.sendMessage({
        event: 'onEvent',
        eventIdentifier: CHATWOOT_ON_START_CONVERSATION,
        data: { hasConversation: true },
      });
    },
    toggleReplyTo(message) {
      this.inReplyTo = message;
    },
    async handleRequestHandoff() {
      try {
        this.isRequestingHandoff = true;
        await this.requestHandoff();
      } catch (error) {
        emitter.emit(BUS_EVENTS.SHOW_ALERT, {
          message: this.$t('CAPTAIN_HANDOFF.ERROR'),
        });
      } finally {
        this.isRequestingHandoff = false;
      }
    },
    async sendTranscript() {
      if (this.hasEmail) {
        try {
          await sendEmailTranscript();
          emitter.emit(BUS_EVENTS.SHOW_ALERT, {
            message: this.$t('EMAIL_TRANSCRIPT.SEND_EMAIL_SUCCESS'),
            type: 'success',
          });
        } catch (error) {
          emitter.$emit(BUS_EVENTS.SHOW_ALERT, {
            message: this.$t('EMAIL_TRANSCRIPT.SEND_EMAIL_ERROR'),
          });
        }
      }
    },
  },
};
</script>

<template>
  <footer
    v-if="!hideReplyBox"
    class="relative z-50 mb-1"
    :class="{
      'rounded-lg': !isWidgetStyleFlat,
      'pt-2.5 shadow-[0px_-20px_20px_1px_rgba(0,_0,_0,_0.05)] dark:shadow-[0px_-20px_20px_1px_rgba(0,_0,_0,_0.15)] rounded-t-none':
        hasReplyTo,
    }"
  >
    <FooterReplyTo
      v-if="hasReplyTo"
      :in-reply-to="inReplyTo"
      @dismiss="inReplyTo = null"
    />
    <CustomButton
      v-if="showCaptainHandoffButton"
      block
      class="mb-2 font-medium"
      :bg-color="widgetColor"
      :text-color="textColor"
      :disabled="isRequestingHandoff"
      @click="handleRequestHandoff"
    >
      {{ $t('CAPTAIN_HANDOFF.BUTTON_TEXT') }}
    </CustomButton>
    <ChatInputWrap
      class="shadow-sm"
      :on-send-message="handleSendMessage"
      :on-send-attachment="handleSendAttachment"
    />
  </footer>
  <div v-else>
    <CustomButton
      class="font-medium"
      block
      :bg-color="widgetColor"
      :text-color="textColor"
      @click="startNewConversation"
    >
      {{ $t('START_NEW_CONVERSATION') }}
    </CustomButton>
    <CustomButton
      v-if="showEmailTranscriptButton"
      type="clear"
      class="font-normal"
      @click="sendTranscript"
    >
      {{ $t('EMAIL_TRANSCRIPT.BUTTON_TEXT') }}
    </CustomButton>
  </div>
</template>
