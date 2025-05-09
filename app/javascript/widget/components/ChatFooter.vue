<template>
  <footer
    v-if="!hideReplyBox"
    class="relative z-50 py-3 px-4 bg-white"
    :class="{
      'pt-2.5 shadow-[0px_-20px_20px_1px_rgba(0,_0,_0,_0.05)] dark:shadow-[0px_-20px_20px_1px_rgba(0,_0,_0,_0.15)] rounded-t-none':
        hasReplyTo || productData,
    }"
  >
    <div class="shadow-effect" />
    <footer-reply-to
      v-if="hasReplyTo && !productData"
      :in-reply-to="inReplyTo"
      @dismiss="inReplyTo = null"
    />
    <footer-ask-about-product
      v-if="productData"
      :product-data="productData"
      @dismiss="productData = null"
    />
    <chat-input-wrap
      :on-send-message="handleSendMessage"
      :on-send-attachment="handleSendAttachment"
    />
  </footer>
  <!-- <footer v-else class="flex justify-center z-50">
    <div
      class="w-full flex flex-col justify-center items-center shadow-[0px_2px_10px_#0000001A] shadow-[0px_0px_2px_#00000033] py-4 px-6 bg-[#FAFAFA] gap-2"
    >
      <h2 class="text-sm font-medium leading-5">How was your experience?</h2>
      <rating :value="ratingValue" @update:value="handleRatingUpdate" />
    </div>
  </footer> -->
  <!-- <div v-else>
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
  </div> -->
</template>

<script>
import { mapActions, mapGetters } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';
import FooterReplyTo from 'widget/components/FooterReplyTo.vue';
import FooterAskAboutProduct from 'widget/components/FooterAskAboutProduct.vue';
import ChatInputWrap from 'widget/components/ChatInputWrap.vue';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { sendEmailTranscript } from 'widget/api/conversation';
import routerMixin from 'widget/mixins/routerMixin';
import { IFrameHelper } from '../helpers/utils';
import { CHATWOOT_ON_START_CONVERSATION } from '../constants/sdkEvents';
// import Rating from '../components/Rating.vue';

export default {
  components: {
    ChatInputWrap,
    FooterReplyTo,
    // Rating,
    FooterAskAboutProduct,
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
      ratingValue: 1,
      productData: null,
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
    this.$emitter.on(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, this.toggleReplyTo);
    this.$emitter.on(BUS_EVENTS.ASK_FOR_PRODUCT, this.toggleAskForProduct);
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
        productIdForMoreInfo: this.productData?.id
          ? this.productData?.id
          : null,
      });
      // reset replyTo message after sending
      this.inReplyTo = null;
      this.productData = null;
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
    toggleAskForProduct(productData) {
      this.productData = productData;
    },
    async sendTranscript() {
      if (this.hasEmail) {
        try {
          await sendEmailTranscript();
          this.$emitter.emit(BUS_EVENTS.SHOW_ALERT, {
            message: this.$t('EMAIL_TRANSCRIPT.SEND_EMAIL_SUCCESS'),
            type: 'success',
          });
        } catch (error) {
          this.$emitter.$emit(BUS_EVENTS.SHOW_ALERT, {
            message: this.$t('EMAIL_TRANSCRIPT.SEND_EMAIL_ERROR'),
          });
        }
      }
    },
    handleRatingUpdate(value) {
      this.ratingValue = value;
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

.shadow-effect {
  position: absolute;
  left: 0;
  top: -2.25rem;
  width: 100%;
  height: 2.25rem;
  background: linear-gradient(180deg, hsla(0, 0%, 99.6%, 0) 30%, #fefefe 90%);
}
</style>
