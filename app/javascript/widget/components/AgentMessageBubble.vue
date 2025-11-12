<template>
  <div class="chat-bubble-wrap">
    <div
      v-if="
        !isCards &&
        !isOptions &&
        !isForm &&
        !isArticle &&
        !isCards &&
        !isCSAT &&
        !isProductCarousel
      "
      class="chat-bubble agent !px-3.5 !py-3"
      :class="$dm('bg-white', 'dark:bg-slate-700 has-dark-mode')"
      style="border-radius: 8px; border: 1px solid #f0f0f0"
    >
      <div
        v-dompurify-html="formatMessage(message, false)"
        class="message-content text-slate-900 dark:text-slate-50"
      />
      <email-input
        v-if="isTemplateEmail"
        :message-id="messageId"
        :message-content-attributes="messageContentAttributes"
      />
      <phone-input
        v-if="isTemplatePhone"
        :message-id="messageId"
        :message-content-attributes="messageContentAttributes"
      />
      <integration-card
        v-if="isIntegrations"
        :message-id="messageId"
        :meeting-data="messageContentAttributes.data"
      />
    </div>

    <order-details-card
      v-if="shouldShowOrderDetailsCard"
      :message-id="messageId"
    />
    <pre-chat-form
      v-if="shouldShowPreChatForm"
      :message-id="messageId"
      :items="messageContentAttributes.items"
      :pre-chat-form-response="
        messageContentAttributes.pre_chat_form_response || {}
      "
    />
    <product-carousel
      v-if="isProductCarousel && messageContentAttributes.items"
      :items="messageContentAttributes.items"
      :selected-products="selectedProducts"
      :update-selected-products="updateSelectedProducts"
      :open-checkout-page="openCheckoutPage"
      :set-selected-products="setSelectedProducts"
      :replace-selected-products="replaceSelectedProducts"
      :message="message"
      :message-id="messageId"
    />
    <tags
      class="mt-2"
      :tags="messageContentAttributes.items"
      :message-id="messageId"
      :previous-selected-replies="
        messageContentAttributes.previous_selected_replies || []
      "
    />
    <message-action v-if="shouldPromptResolutions && isLastMessage" />
    <div v-if="isOptions">
      <chat-options
        :title="message"
        :options="messageContentAttributes.items"
        :hide-fields="!!messageContentAttributes.submitted_values"
        @click="onOptionSelect"
      />
    </div>
    <chat-form
      v-if="isForm && !messageContentAttributes.submitted_values"
      :items="messageContentAttributes.items"
      :button-label="messageContentAttributes.button_label"
      :submitted-values="messageContentAttributes.submitted_values"
      @submit="onFormSubmit"
    />
    <div v-if="isCards">
      <chat-card
        v-for="item in messageContentAttributes.items"
        :key="item.title"
        :media-url="item.media_url"
        :title="item.title"
        :description="item.description"
        :actions="item.actions"
      />
    </div>
    <div v-if="isArticle">
      <chat-article :items="messageContentAttributes.items" />
    </div>
    <customer-satisfaction
      v-if="isCSAT && isLastMessageCSAT"
      :message-content-attributes="messageContentAttributes.submitted_values"
      :message-id="messageId"
    />
  </div>
</template>

<script>
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import ChatCard from 'shared/components/ChatCard.vue';
import ChatForm from 'shared/components/ChatForm.vue';
import ChatOptions from 'shared/components/ChatOptions.vue';
import ChatArticle from './template/Article.vue';
import EmailInput from './template/EmailInput.vue';
import PhoneInput from './template/PhoneInput.vue';
import PreChatForm from './PreChatForm.vue';
import CustomerSatisfaction from 'shared/components/CustomerSatisfaction.vue';
import darkModeMixin from 'widget/mixins/darkModeMixin.js';
import IntegrationCard from './template/IntegrationCard.vue';
import Tags from './Tags.vue';
import MessageAction from './MessageAction.vue';
import ProductCarousel from 'shared/components/ProductCarousel.vue';
// import PhoneInput from 'dashboard/components/widgets/forms/PhoneInput.vue';
import OrderDetailsCard from './OrderDetailsCard.vue';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { mapGetters } from 'vuex';

export default {
  name: 'AgentMessageBubble',
  components: {
    ChatArticle,
    ChatCard,
    ChatForm,
    ChatOptions,
    EmailInput,
    PhoneInput,
    CustomerSatisfaction,
    IntegrationCard,
    Tags,
    ProductCarousel,
    // PhoneInput,
    OrderDetailsCard,
    MessageAction,
    PreChatForm,
  },
  mixins: [messageFormatterMixin, darkModeMixin],
  props: {
    message: { type: String, default: null },
    contentType: { type: String, default: null },
    messageType: { type: Number, default: null },
    messageId: { type: Number, default: null },
    messageContentAttributes: {
      type: Object,
      default: () => {},
    },
    selectedProducts: {
      type: Array,
      default: () => [],
    },
    updateSelectedProducts: {
      type: Function,
      default: () => {},
    },
    openCheckoutPage: {
      type: Function,
      default: () => {},
    },
    setSelectedProducts: {
      type: Function,
      default: () => {},
    },
    replaceSelectedProducts: {
      type: Function,
      default: () => {},
    },
    isLastMessage: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    ...mapGetters({
      lastMessage: 'conversation/getLastMessage',
    }),
    isTemplate() {
      return this.messageType === 3;
    },
    shouldPromptResolutions() {
      return this.messageContentAttributes?.should_prompt_resolution;
    },
    shouldShowQuickReply() {
      if (
        this.contentType === 'quick_reply' &&
        !this.messageContentAttributes.selected_reply
      ) {
        return true;
      }
      return false;
    },
    isProductCarousel() {
      if (this.contentType === 'product_carousel') {
        return true;
      }
      return false;
    },
    shouldShowOrderDetailsCard() {
      return (
        this.contentType === 'order_input' &&
        !(
          this.messageContentAttributes.user_phone_number ||
          this.messageContentAttributes.user_order_id
        )
      );
    },
    shouldShowPreChatForm() {
      return this.contentType === 'pre_chat_form';
    },
    isTemplateEmail() {
      return this.contentType === 'input_email';
    },
    isTemplatePhone() {
      return this.contentType === 'input_phone';
    },
    isCards() {
      return this.contentType === 'cards';
    },
    isOptions() {
      return this.contentType === 'input_select';
    },
    isForm() {
      return this.contentType === 'form';
    },
    isArticle() {
      return this.contentType === 'article';
    },
    isCSAT() {
      return this.contentType === 'input_csat';
    },
    isLastMessageCSAT() {
      return (
        this.messageId === this.lastMessage.id &&
        this.lastMessage.content_type === 'input_csat'
      );
    },
    isIntegrations() {
      return this.contentType === 'integrations';
    },
  },
  mounted() {
    if (this.isCSAT) {
      this.sendDataForIsCSAT(this.isCSAT);
    }
  },
  methods: {
    onResponse(messageResponse) {
      this.$store.dispatch('message/update', messageResponse);
    },
    onOptionSelect(selectedOption) {
      this.onResponse({
        submittedValues: [selectedOption],
        messageId: this.messageId,
      });
    },
    onFormSubmit(formValues) {
      const formValuesAsArray = Object.keys(formValues).map(key => ({
        name: key,
        value: formValues[key],
      }));
      this.onResponse({
        submittedValues: formValuesAsArray,
        messageId: this.messageId,
      });
    },
    sendDataForIsCSAT(isCSAT) {
      emitter.emit(BUS_EVENTS.SEND_IS_CSAT_MESSAGE, isCSAT);
    },
  },
};
</script>
