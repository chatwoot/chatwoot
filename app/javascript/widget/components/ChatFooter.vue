<script>
import { mapActions, mapGetters } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';
import CustomButton from 'shared/components/Button.vue';
import FooterReplyTo from 'widget/components/FooterReplyTo.vue';
import ChatInputWrap from 'widget/components/ChatInputWrap.vue';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { sendEmailTranscript } from 'widget/api/conversation';
import { useRouter } from 'vue-router';
import { IFrameHelper } from '../helpers/utils';
import { CHATWOOT_ON_START_CONVERSATION } from '../constants/sdkEvents';
import { emitter } from 'shared/helpers/mitt';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import { useCsatRequest } from '../composables/useCsatRequest';

const TRANSCRIPT_COOLDOWN_MS = 15000;

export default {
  components: {
    ChatInputWrap,
    CustomButton,
    FooterReplyTo,
    FluentIcon,
  },
  setup() {
    const router = useRouter();
    const { canRequestCsat } = useCsatRequest();
    return { router, canRequestCsat };
  },
  data() {
    return {
      inReplyTo: null,
      isSendingTranscript: false,
      transcriptCooldown: false,
      transcriptCooldownTimer: null,
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
      return this.hasEmail;
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
  beforeUnmount() {
    clearTimeout(this.transcriptCooldownTimer);
  },
  methods: {
    ...mapActions('conversation', [
      'sendMessage',
      'sendAttachment',
      'requestCSAT',
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
    async handleRequestCSAT() {
      await this.requestCSAT();
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
    startTranscriptCooldown() {
      this.transcriptCooldown = true;
      clearTimeout(this.transcriptCooldownTimer);
      this.transcriptCooldownTimer = setTimeout(() => {
        this.transcriptCooldown = false;
      }, TRANSCRIPT_COOLDOWN_MS);
    },
    async sendTranscript() {
      if (
        !this.hasEmail ||
        this.isSendingTranscript ||
        this.transcriptCooldown
      ) {
        return;
      }
      this.isSendingTranscript = true;
      try {
        await sendEmailTranscript();
        this.startTranscriptCooldown();
        emitter.emit(BUS_EVENTS.SHOW_ALERT, {
          message: this.$t('EMAIL_TRANSCRIPT.SEND_EMAIL_SUCCESS'),
          type: 'success',
        });
      } catch (error) {
        emitter.emit(BUS_EVENTS.SHOW_ALERT, {
          message: this.$t('EMAIL_TRANSCRIPT.SEND_EMAIL_ERROR'),
        });
      } finally {
        this.isSendingTranscript = false;
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
    <ChatInputWrap
      class="shadow-sm"
      :on-send-message="handleSendMessage"
      :on-send-attachment="handleSendAttachment"
      :on-request-csat="handleRequestCSAT"
    />
  </footer>
  <div v-else>
    <div class="flex gap-2 items-stretch">
      <CustomButton
        class="font-medium flex-1"
        :bg-color="widgetColor"
        :text-color="textColor"
        @click="startNewConversation"
      >
        {{ $t('START_NEW_CONVERSATION') }}
      </CustomButton>
      <button
        v-if="canRequestCsat"
        class="flex items-center justify-center shrink-0 min-w-12 rounded-lg text-n-slate-12 bg-n-background shadow-sm hover:bg-n-slate-2 dark:hover:bg-n-solid-3 transition-colors"
        :aria-label="$t('CSAT.RATE_CHAT_BUTTON')"
        :title="$t('CSAT.RATE_CHAT_BUTTON')"
        @click="handleRequestCSAT"
      >
        <FluentIcon icon="thumb-up" icon-lib="lucide" />
      </button>
    </div>
    <CustomButton
      v-if="showEmailTranscriptButton"
      type="clear"
      class="font-normal"
      :disabled="isSendingTranscript || transcriptCooldown"
      @click="sendTranscript"
    >
      {{ $t('EMAIL_TRANSCRIPT.BUTTON_TEXT') }}
    </CustomButton>
  </div>
</template>
