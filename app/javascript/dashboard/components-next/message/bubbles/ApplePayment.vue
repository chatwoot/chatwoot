<template>
  <div class="apple-payment-bubble">
    <div class="payment-container">
      <div class="payment-header">
        <div class="payment-icon">
          <i class="i-ph-credit-card-duotone text-2xl"></i>
        </div>
        <div class="payment-content">
          <h3 class="payment-title">{{ paymentRequest.total.label }}</h3>
          <p class="payment-amount">
            {{ formatCurrency(paymentRequest.total.amount, paymentRequest.currency_code) }}
          </p>
        </div>
      </div>

      <div class="payment-items" v-if="showDetails">
        <div
          v-for="(item, index) in paymentRequest.line_items"
          :key="index"
          class="payment-item"
        >
          <span class="item-label">{{ item.label }}</span>
          <span class="item-amount">
            {{ formatCurrency(item.amount, paymentRequest.currency_code) }}
          </span>
        </div>
      </div>

      <div class="payment-actions">
        <button
          v-if="canPay && !isProcessing"
          class="apple-pay-button"
          @click="initiatePayment"
        >
          <div class="apple-pay-logo">
            <span class="apple-logo"></span>
            <span class="pay-text">Pay</span>
          </div>
        </button>

        <button
          v-if="!canPay && !isProcessing"
          class="setup-button"
          @click="setupApplePay"
        >
          <i class="i-ph-gear mr-2"></i>
          {{ $t('APPLE_MESSAGES.PAYMENT.SETUP_APPLE_PAY') }}
        </button>

        <div v-if="isProcessing" class="payment-loading">
          <div class="loading-spinner"></div>
          <span>{{ $t('APPLE_MESSAGES.PAYMENT.PROCESSING') }}</span>
        </div>
      </div>

      <div class="payment-details-toggle">
        <button
          class="details-button"
          @click="showDetails = !showDetails"
        >
          <span>{{ showDetails ? $t('APPLE_MESSAGES.PAYMENT.HIDE_DETAILS') : $t('APPLE_MESSAGES.PAYMENT.SHOW_DETAILS') }}</span>
          <i :class="showDetails ? 'i-ph-caret-up' : 'i-ph-caret-down'"></i>
        </button>
      </div>

      <div v-if="errorMessage" class="payment-error">
        <i class="i-ph-warning-circle mr-2"></i>
        {{ errorMessage }}
      </div>

      <div v-if="paymentResult" class="payment-success">
        <i class="i-ph-check-circle mr-2"></i>
        {{ $t('APPLE_MESSAGES.PAYMENT.SUCCESS', { amount: formatCurrency(paymentResult.amount, paymentResult.currency) }) }}
        <div class="transaction-id">
          {{ $t('APPLE_MESSAGES.PAYMENT.TRANSACTION_ID', { id: paymentResult.transaction_id }) }}
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';

export default {
  props: {
    paymentRequest: {
      type: Object,
      required: true,
    },
    merchantSession: {
      type: Object,
      required: true,
    },
    mspId: {
      type: String,
      required: true,
    },
    endpoints: {
      type: Object,
      required: true,
    },
  },
  emits: ['paymentSuccess', 'paymentError', 'paymentCancel'],
  setup(props, { emit }) {
    const { t } = useI18n();

    const showDetails = ref(false);
    const isProcessing = ref(false);
    const errorMessage = ref('');
    const paymentResult = ref(null);
    const applePaySession = ref(null);

    const canPay = computed(() => {
      // Check if Apple Pay is available
      return typeof window !== 'undefined' &&
             window.ApplePaySession &&
             ApplePaySession.canMakePayments();
    });

    const formatCurrency = (amount, currency) => {
      return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: currency || 'USD',
      }).format(parseFloat(amount));
    };

    const initiatePayment = async () => {
      if (!canPay.value) {
        errorMessage.value = t('APPLE_MESSAGES.PAYMENT.APPLE_PAY_NOT_AVAILABLE');
        return;
      }

      try {
        isProcessing.value = true;
        errorMessage.value = '';

        // Create Apple Pay session
        const paymentRequest = createApplePayRequest();
        const session = new ApplePaySession(3, paymentRequest);

        applePaySession.value = session;

        // Set up event handlers
        session.onvalidatemerchant = handleValidateMerchant;
        session.onpaymentmethodselected = handlePaymentMethodSelected;
        session.onshippingmethodselected = handleShippingMethodSelected;
        session.onshippingcontactselected = handleShippingContactSelected;
        session.onpaymentauthorized = handlePaymentAuthorized;
        session.oncancel = handlePaymentCancel;

        // Begin the payment session
        session.begin();

      } catch (error) {
        errorMessage.value = error.message;
        emit('paymentError', error.message);
        isProcessing.value = false;
      }
    };

    const createApplePayRequest = () => {
      return {
        countryCode: props.paymentRequest.country_code,
        currencyCode: props.paymentRequest.currency_code,
        supportedNetworks: props.paymentRequest.supported_networks,
        merchantCapabilities: props.paymentRequest.merchant_capabilities,
        total: props.paymentRequest.total,
        lineItems: props.paymentRequest.line_items,
        shippingMethods: props.paymentRequest.shipping_methods || [],
        requiredBillingContactFields: props.paymentRequest.required_billing_contact_fields || [],
        requiredShippingContactFields: props.paymentRequest.required_shipping_contact_fields || [],
        shippingType: 'shipping',
        supportedCountries: props.paymentRequest.supported_countries || ['US'],
      };
    };

    const handleValidateMerchant = async (event) => {
      try {
        const response = await fetch(`/apple_messages_for_business/${props.mspId}/payment_gateway/merchant_session`, {
          method: 'POST',
          headers: {
            'Content-Type' => 'application/json',
            'X-CSRF-Token' => document.querySelector('meta[name="csrf-token"]')?.content,
          },
          body: JSON.stringify({
            validationURL: event.validationURL,
            domainName: window.location.hostname,
          }),
        });

        const sessionData = await response.json();

        if (sessionData.error) {
          throw new Error(sessionData.error);
        }

        applePaySession.value.completeMerchantValidation(sessionData.merchantSession);
      } catch (error) {
        errorMessage.value = `Merchant validation failed: ${error.message}`;
        applePaySession.value.abort();
      }
    };

    const handlePaymentMethodSelected = (event) => {
      // Payment method was selected, complete with current total
      applePaySession.value.completePaymentMethodSelection({
        newTotal: props.paymentRequest.total,
        newLineItems: props.paymentRequest.line_items,
      });
    };

    const handleShippingMethodSelected = async (event) => {
      try {
        const response = await fetch(`/apple_messages_for_business/${props.mspId}/payment_gateway/method_update`, {
          method: 'POST',
          headers: {
            'Content-Type' => 'application/json',
            'X-CSRF-Token' => document.querySelector('meta[name="csrf-token"]')?.content,
          },
          body: JSON.stringify({
            type: 'shipping_method',
            data: event.shippingMethod,
          }),
        });

        const updateData = await response.json();

        if (updateData.error) {
          throw new Error(updateData.error);
        }

        applePaySession.value.completeShippingMethodSelection({
          newTotal: updateData.total,
          newLineItems: updateData.line_items || props.paymentRequest.line_items,
        });
      } catch (error) {
        applePaySession.value.completeShippingMethodSelection({
          status: ApplePaySession.STATUS_FAILURE,
        });
      }
    };

    const handleShippingContactSelected = async (event) => {
      try {
        const response = await fetch(`/apple_messages_for_business/${props.mspId}/payment_gateway/method_update`, {
          method: 'POST',
          headers: {
            'Content-Type' => 'application/json',
            'X-CSRF-Token' => document.querySelector('meta[name="csrf-token"]')?.content,
          },
          body: JSON.stringify({
            type: 'shipping_contact',
            data: event.shippingContact,
          }),
        });

        const updateData = await response.json();

        if (updateData.error) {
          throw new Error(updateData.error);
        }

        applePaySession.value.completeShippingContactSelection({
          newShippingMethods: updateData.shipping_methods,
          newTotal: updateData.total || props.paymentRequest.total,
          newLineItems: updateData.line_items || props.paymentRequest.line_items,
        });
      } catch (error) {
        applePaySession.value.completeShippingContactSelection({
          status: ApplePaySession.STATUS_FAILURE,
        });
      }
    };

    const handlePaymentAuthorized = async (event) => {
      try {
        const response = await fetch(`/apple_messages_for_business/${props.mspId}/payment_gateway/process_payment`, {
          method: 'POST',
          headers: {
            'Content-Type' => 'application/json',
            'X-CSRF-Token' => document.querySelector('meta[name="csrf-token"]')?.content,
          },
          body: JSON.stringify({
            paymentToken: event.payment.token,
            paymentData: {
              billingContact: event.payment.billingContact,
              shippingContact: event.payment.shippingContact,
              total: props.paymentRequest.total,
              line_items: props.paymentRequest.line_items,
            },
          }),
        });

        const paymentResponse = await response.json();

        if (paymentResponse.success) {
          applePaySession.value.completePayment({
            status: ApplePaySession.STATUS_SUCCESS,
          });

          paymentResult.value = paymentResponse;
          emit('paymentSuccess', paymentResponse);
        } else {
          applePaySession.value.completePayment({
            status: ApplePaySession.STATUS_FAILURE,
          });

          errorMessage.value = paymentResponse.error;
          emit('paymentError', paymentResponse.error);
        }
      } catch (error) {
        applePaySession.value.completePayment({
          status: ApplePaySession.STATUS_FAILURE,
        });

        errorMessage.value = `Payment processing failed: ${error.message}`;
        emit('paymentError', error.message);
      } finally {
        isProcessing.value = false;
      }
    };

    const handlePaymentCancel = () => {
      isProcessing.value = false;
      emit('paymentCancel');
    };

    const setupApplePay = () => {
      // Redirect to Apple Wallet or show setup instructions
      window.open('https://support.apple.com/en-us/HT204506', '_blank');
    };

    onMounted(() => {
      // Check Apple Pay availability and setup
      if (typeof window !== 'undefined' && window.ApplePaySession) {
        // Apple Pay is available
      } else {
        errorMessage.value = t('APPLE_MESSAGES.PAYMENT.APPLE_PAY_NOT_SUPPORTED');
      }
    });

    return {
      showDetails,
      isProcessing,
      errorMessage,
      paymentResult,
      canPay,
      formatCurrency,
      initiatePayment,
      setupApplePay,
    };
  },
};
</script>

<style scoped>
.apple-payment-bubble {
  @apply bg-white rounded-lg shadow-md p-4 max-w-sm mx-auto border border-gray-200;
}

.payment-container {
  @apply space-y-4;
}

.payment-header {
  @apply flex items-start space-x-3;
}

.payment-icon {
  @apply w-12 h-12 bg-green-100 rounded-full flex items-center justify-center text-green-600 flex-shrink-0;
}

.payment-content {
  @apply flex-1;
}

.payment-title {
  @apply text-lg font-semibold text-gray-900 mb-1;
}

.payment-amount {
  @apply text-2xl font-bold text-green-600;
}

.payment-items {
  @apply space-y-2 border-t border-gray-200 pt-4;
}

.payment-item {
  @apply flex justify-between items-center text-sm;
}

.item-label {
  @apply text-gray-700;
}

.item-amount {
  @apply font-medium text-gray-900;
}

.payment-actions {
  @apply flex flex-col space-y-2;
}

.apple-pay-button {
  @apply bg-black text-white rounded-lg p-3 font-medium hover:bg-gray-800 transition-colors duration-200 flex items-center justify-center;
}

.apple-pay-logo {
  @apply flex items-center space-x-2;
}

.apple-logo {
  @apply w-5 h-5 bg-white rounded-sm flex items-center justify-center text-black text-xs font-bold;
}

.apple-logo::before {
  content: '';
}

.pay-text {
  @apply text-white font-medium;
}

.setup-button {
  @apply bg-blue-600 text-white rounded-lg p-3 font-medium hover:bg-blue-700 transition-colors duration-200 flex items-center justify-center;
}

.payment-loading {
  @apply flex items-center justify-center space-x-2 py-3 text-gray-600;
}

.loading-spinner {
  @apply w-4 h-4 border-2 border-blue-600 border-t-transparent rounded-full animate-spin;
}

.payment-details-toggle {
  @apply border-t border-gray-200 pt-4;
}

.details-button {
  @apply w-full text-center text-blue-600 hover:text-blue-700 text-sm font-medium flex items-center justify-center space-x-1;
}

.payment-error {
  @apply flex items-start space-x-2 text-red-600 text-sm bg-red-50 p-3 rounded-lg;
}

.payment-success {
  @apply text-green-600 text-sm bg-green-50 p-3 rounded-lg;
}

.transaction-id {
  @apply text-xs text-green-500 mt-1 font-mono;
}
</style>