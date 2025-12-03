<template>
  <div class="conversation--container" :class="colorSchemeClass">
    <div class="conversation-wrap" :class="{ 'is-typing': isAgentTyping }">
      <div v-if="isFetchingList" class="message--loader">
        <spinner />
      </div>
      <div
        v-for="groupedMessage in groupedMessages"
        :key="groupedMessage.date"
        class="messages-wrap"
      >
        <div class="px-3">
          <date-separator :date="groupedMessage.date" />
        </div>

        <chat-message
          v-for="message in filterGroupedMessages(groupedMessage.messages)"
          :key="message.id"
          :message="message"
          :selected-products="selectedProducts"
          :update-selected-products="updateSelectedProducts"
          :open-checkout-page="openCheckoutPage"
          :set-selected-products="setSelectProducts"
          :replace-selected-products="replaceSelectedProducts"
          :all-grouped-messages="filterGroupedMessages(groupedMessage.messages)"
        />
      </div>
      <agent-typing-bubble v-if="showStatusIndicator" />
      <!-- <div v-if="selectedProducts.length > 0" class="cart-icon-container">
        <button
          :style="{ backgroundColor: channelConfig.widgetColor }"
          class="cart-icon"
          @click="openCheckoutPage(selectedProducts)"
        >
          <img
            width="20"
            height="20"
            src="~dashboard/assets/cart-icon.svg"
            alt="cart"
          />
          <span class="cart-count">{{ totalCartItems }}</span>
        </button>
      </div> -->
    </div>
  </div>
</template>

<script>
import ChatMessage from 'widget/components/ChatMessage.vue';
import AgentTypingBubble from 'widget/components/AgentTypingBubble.vue';
import DateSeparator from 'shared/components/DateSeparator.vue';
import Spinner from 'shared/components/Spinner.vue';
import darkModeMixin from 'widget/mixins/darkModeMixin';
import { MESSAGE_TYPE } from 'shared/constants/messages';
import { mapActions, mapGetters } from 'vuex';
import configMixin from 'widget/mixins/configMixin';

export default {
  name: 'ConversationWrap',
  components: {
    ChatMessage,
    AgentTypingBubble,
    DateSeparator,
    Spinner,
  },
  mixins: [darkModeMixin, configMixin],
  props: {
    groupedMessages: {
      type: Array,
      default: () => [],
    },
  },

  data() {
    return {
      previousScrollHeight: 0,
      previousConversationSize: 0,
      selectedProducts: [],
    };
  },
  computed: {
    ...mapGetters({
      earliestMessage: 'conversation/getEarliestMessage',
      lastMessage: 'conversation/getLastMessage',
      allMessagesLoaded: 'conversation/getAllMessagesLoaded',
      isFetchingList: 'conversation/getIsFetchingList',
      conversationSize: 'conversation/getConversationSize',
      isAgentTyping: 'conversation/getIsAgentTyping',
      conversationAttributes: 'conversationAttributes/getConversationParams',
    }),
    totalCartItems() {
      if (this.selectedProducts.length === 0) {
        return 0;
      }
      return this.selectedProducts.reduce(
        (acc, product) => acc + product.quantity,
        0
      );
    },
    colorSchemeClass() {
      return `${this.darkMode === 'dark' ? 'dark-scheme' : 'light-scheme'}`;
    },
    showStatusIndicator() {
      const { status } = this.conversationAttributes;
      const isConversationInPendingStatus = ['open', 'pending'].includes(
        status?.toLowerCase()
      );
      const isAssignedToBitespeedBot =
        this.conversationAttributes?.assignee?.name
          .toLowerCase()
          .includes('bitespeed');
      const isLastMessageIncoming =
        this.lastMessage.message_type === MESSAGE_TYPE.INCOMING;
      const isHelpedMessage = ['that helped', 'need more help'].includes(
        this.lastMessage?.content?.toLowerCase()
      );
      return (
        this.isAgentTyping ||
        (isConversationInPendingStatus &&
          isLastMessageIncoming &&
          !isHelpedMessage &&
          isAssignedToBitespeedBot)
      );
    },
  },
  watch: {
    allMessagesLoaded() {
      this.previousScrollHeight = 0;
    },
  },
  mounted() {
    // how to get the url of the page in which this page is rendered as a iframe
    this.$el.addEventListener('scroll', this.handleScroll);
    this.scrollToBottom();
    this.fetchCartData();
  },
  updated() {
    if (this.previousConversationSize !== this.conversationSize) {
      this.previousConversationSize = this.conversationSize;
      this.scrollToBottom();
    }
  },
  unmounted() {
    this.$el.removeEventListener('scroll', this.handleScroll);
  },

  methods: {
    ...mapActions('conversation', ['fetchOldConversations']),
    scrollToBottom() {
      const container = this.$el;
      container.scrollTop = container.scrollHeight - this.previousScrollHeight;
      this.previousScrollHeight = 0;
    },
    fetchCartData() {
      fetch(`https://mechdrift.myshopify.com/cart.js`)
        .then(res => res.json())
        .then(newCart => {
          const cartItems = newCart.items;
          const convertedCartItems = cartItems.map(item => ({
            id: item.id,
            quantity: item.quantity,
            price: item.price,
            currency: newCart.currency,
          }));
          this.selectedProducts = convertedCartItems;
        })
        .catch(() => {});
    },
    filterGroupedMessages(groupedMessages) {
      return groupedMessages?.filter(
        msg =>
          (msg?.content && msg?.content.trim() !== '') ||
          (msg?.attachments && msg?.attachments.length > 0)
      );
      // return groupedMessages?.filter(
      //   msg => msg?.content && msg?.content.trim() !== ''
      // ).sort((a, b) => {
      //   console.log("timingData", {a: a.created_at, b: b.created_at})
      //   console.log("First Data", {a: a.content_attributes.external_created_at || a.created_at, b: b.content_attributes.external_created_at || b.created_at})
      //     return (a.content_attributes.external_created_at || a.created_at) - (b.content_attributes.external_created_at || b.created_at) ;
      //   });
    },
    openCheckoutPage(selectedProducts) {
      const shopUrl = selectedProducts[0].shopUrl;
      const lineItems = selectedProducts.map(product => ({
        variant_id: product.id,
        quantity: product.quantity,
        price: product.price,
        currency: product.currency,
      }));
      window.open(
        `https://mcfsmik3g0.execute-api.us-east-1.amazonaws.com/chatbot/checkout?shopUrl=${shopUrl}&lineItems=${encodeURIComponent(
          JSON.stringify(lineItems)
        )}`,
        '_blank'
      );
    },

    updateSelectedProducts(
      productId,
      quantity,
      currency,
      price,
      shopUrl,
      event
    ) {
      event.stopPropagation();
      const existingProduct = this.selectedProducts.find(
        p => p.id === productId
      );
      if (existingProduct) {
        if (quantity === 0) {
          this.selectedProducts = this.selectedProducts.filter(
            p => p.id !== productId
          );
        } else {
          this.selectedProducts = this.selectedProducts.map(p =>
            p.id === productId ? { ...p, quantity } : p
          );
        }
      } else {
        this.selectedProducts = [
          ...this.selectedProducts,
          {
            id: productId,
            quantity,
            currency,
            price,
            shopUrl,
          },
        ];
      }
      return this.selectedProducts;
    },
    setSelectProducts(products) {
      this.selectedProducts = [...this.selectedProducts, ...products];
    },
    replaceSelectedProducts(products) {
      // Replace entire selected products array (used for cart sync from Shopify)
      this.selectedProducts = products;
    },
    handleScroll() {
      if (
        this.isFetchingList ||
        this.allMessagesLoaded ||
        !this.conversationSize
      ) {
        return;
      }

      if (this.$el.scrollTop < 100) {
        this.fetchOldConversations({ before: this.earliestMessage.id });
        this.previousScrollHeight = this.$el.scrollHeight;
      }
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';
@import '~widget/assets/scss/mixins.scss';

.conversation--container {
  display: flex;
  flex-direction: column;
  flex: 1;
  overflow-y: auto;
  color-scheme: light dark;
  overflow-x: hidden;

  &.light-scheme {
    color-scheme: light;
  }
  &.dark-scheme {
    color-scheme: dark;
  }
}

.cart-icon-container {
  position: fixed;
  bottom: 120px;
  right: 10px;
  margin-right: 10px;
}

.cart-icon {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
}

.cart-count {
  position: absolute;
  top: 0;
  right: 0;
  font-size: 10px;
  color: white;
  background-color: red;
  border-radius: 50%;
  width: 15px;
  height: 15px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.conversation-wrap {
  flex: 1;
  padding: $space-large $space-small $space-large $space-small;
  position: relative;
  width: 100%;
}

.message--loader {
  text-align: center;
}
</style>
