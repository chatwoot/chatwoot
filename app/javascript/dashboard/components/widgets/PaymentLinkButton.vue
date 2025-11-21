<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';
import PaymentLinkModal from './conversation/PaymentLinkModal.vue';
import PaymentLinksAPI from '../../api/paymentLinks';

export default {
  components: {
    NextButton,
    PaymentLinkModal,
  },
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
  },
  data() {
    return {
      showPaymentLinkModal: false,
      isSubmitting: false,
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      accountId: 'getCurrentAccountId',
    }),
  },
  methods: {
    openPaymentLinkModal() {
      this.showPaymentLinkModal = true;
    },
    closePaymentLinkModal() {
      this.showPaymentLinkModal = false;
    },
    async handleSubmit(paymentData) {
      this.isSubmitting = true;
      try {
        const response = await PaymentLinksAPI.create(
          this.accountId,
          this.conversationId,
          paymentData
        );

        // Send the payment link as a message in the conversation
        await this.$store.dispatch('sendMessage', {
          conversationId: this.conversationId,
          message: this.formatPaymentLinkMessage(response.data),
        });

        useAlert(this.$t('PAYMENT_LINK.SUCCESS'));
        this.closePaymentLinkModal();
      } catch (error) {
        const errorMessage =
          error.response?.data?.message || this.$t('PAYMENT_LINK.ERROR');
        useAlert(errorMessage);
      } finally {
        this.isSubmitting = false;
      }
    },
    formatPaymentLinkMessage(paymentData) {
      const { payment_url, payment_id, amount, currency } = paymentData;
      return `Payment Link Generated\n\nAmount: ${amount} ${currency}\nPayment ID: ${payment_id}\n\nClick here to pay: ${payment_url}`;
    },
  },
};
</script>

<template>
  <div class="relative">
    <NextButton
      v-tooltip.top-end="$t('PAYMENT_LINK.BUTTON_TEXT')"
      icon="i-ph-credit-card"
      slate
      faded
      sm
      @click="openPaymentLinkModal"
    />
    <woot-modal
      v-model:show="showPaymentLinkModal"
      :on-close="closePaymentLinkModal"
    >
      <PaymentLinkModal
        :show="showPaymentLinkModal"
        :current-chat="currentChat"
        :is-submitting="isSubmitting"
        @cancel="closePaymentLinkModal"
        @submit="handleSubmit"
        @update:show="showPaymentLinkModal = $event"
      />
    </woot-modal>
  </div>
</template>
