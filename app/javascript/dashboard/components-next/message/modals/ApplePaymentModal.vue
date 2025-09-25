<template>
  <woot-modal :show="show" :on-close="onClose" size="large">
    <div class="apple-payment-modal">
      <div class="modal-header">
        <h2 class="modal-title">
          {{ $t('APPLE_MESSAGES.PAYMENT.MODAL.TITLE') }}
        </h2>
        <p class="modal-description">
          {{ $t('APPLE_MESSAGES.PAYMENT.MODAL.DESCRIPTION') }}
        </p>
      </div>

      <div class="modal-content">
        <div class="payment-setup">
          <form @submit.prevent="createPaymentMessage" class="payment-form">
            <div class="form-section">
              <h3 class="section-title">
                {{ $t('APPLE_MESSAGES.PAYMENT.MODAL.BASIC_INFO') }}
              </h3>

              <div class="form-row">
                <div class="form-group">
                  <label class="form-label">
                    {{ $t('APPLE_MESSAGES.PAYMENT.MODAL.MERCHANT_NAME') }}
                  </label>
                  <input
                    v-model="paymentData.merchantName"
                    type="text"
                    class="form-input"
                    required
                  />
                </div>

                <div class="form-group">
                  <label class="form-label">
                    {{ $t('APPLE_MESSAGES.PAYMENT.MODAL.CURRENCY') }}
                  </label>
                  <select v-model="paymentData.currencyCode" class="form-select" required>
                    <option value="USD">USD - US Dollar</option>
                    <option value="EUR">EUR - Euro</option>
                    <option value="GBP">GBP - British Pound</option>
                    <option value="CAD">CAD - Canadian Dollar</option>
                    <option value="JPY">JPY - Japanese Yen</option>
                  </select>
                </div>
              </div>

              <div class="form-group">
                <label class="form-label">
                  {{ $t('APPLE_MESSAGES.PAYMENT.MODAL.COUNTRY') }}
                </label>
                <select v-model="paymentData.countryCode" class="form-select" required>
                  <option value="US">United States</option>
                  <option value="CA">Canada</option>
                  <option value="GB">United Kingdom</option>
                  <option value="DE">Germany</option>
                  <option value="FR">France</option>
                  <option value="JP">Japan</option>
                  <option value="AU">Australia</option>
                </select>
              </div>
            </div>

            <div class="form-section">
              <h3 class="section-title">
                {{ $t('APPLE_MESSAGES.PAYMENT.MODAL.LINE_ITEMS') }}
              </h3>

              <div class="line-items-container">
                <div
                  v-for="(item, index) in paymentData.lineItems"
                  :key="index"
                  class="line-item"
                >
                  <div class="form-row">
                    <div class="form-group flex-2">
                      <input
                        v-model="item.label"
                        type="text"
                        class="form-input"
                        :placeholder="$t('APPLE_MESSAGES.PAYMENT.MODAL.ITEM_NAME')"
                        required
                      />
                    </div>
                    <div class="form-group flex-1">
                      <div class="input-group">
                        <span class="input-prefix">{{ getCurrencySymbol(paymentData.currencyCode) }}</span>
                        <input
                          v-model="item.amount"
                          type="number"
                          step="0.01"
                          min="0"
                          class="form-input"
                          :placeholder="$t('APPLE_MESSAGES.PAYMENT.MODAL.AMOUNT')"
                          required
                        />
                      </div>
                    </div>
                    <button
                      type="button"
                      class="remove-item-btn"
                      @click="removeLineItem(index)"
                    >
                      <i class="i-ph-x"></i>
                    </button>
                  </div>
                </div>

                <button
                  type="button"
                  class="add-item-btn"
                  @click="addLineItem"
                >
                  <i class="i-ph-plus mr-2"></i>
                  {{ $t('APPLE_MESSAGES.PAYMENT.MODAL.ADD_ITEM') }}
                </button>
              </div>

              <div class="total-section">
                <div class="total-row">
                  <span class="total-label">{{ $t('APPLE_MESSAGES.PAYMENT.MODAL.TOTAL') }}</span>
                  <span class="total-amount">
                    {{ formatCurrency(calculateTotal(), paymentData.currencyCode) }}
                  </span>
                </div>
              </div>
            </div>

            <div class="form-section">
              <h3 class="section-title">
                {{ $t('APPLE_MESSAGES.PAYMENT.MODAL.SHIPPING_OPTIONS') }}
              </h3>

              <div class="checkbox-group">
                <label class="checkbox-label">
                  <input
                    v-model="paymentData.requiresShipping"
                    type="checkbox"
                    class="checkbox"
                  >
                  <span class="checkmark"></span>
                  {{ $t('APPLE_MESSAGES.PAYMENT.MODAL.REQUIRES_SHIPPING') }}
                </label>
              </div>

              <div v-if="paymentData.requiresShipping" class="shipping-methods">
                <div
                  v-for="(method, index) in paymentData.shippingMethods"
                  :key="index"
                  class="shipping-method"
                >
                  <div class="form-row">
                    <div class="form-group flex-2">
                      <input
                        v-model="method.label"
                        type="text"
                        class="form-input"
                        :placeholder="$t('APPLE_MESSAGES.PAYMENT.MODAL.SHIPPING_LABEL')"
                      />
                    </div>
                    <div class="form-group flex-1">
                      <input
                        v-model="method.detail"
                        type="text"
                        class="form-input"
                        :placeholder="$t('APPLE_MESSAGES.PAYMENT.MODAL.SHIPPING_DETAIL')"
                      />
                    </div>
                    <div class="form-group flex-1">
                      <div class="input-group">
                        <span class="input-prefix">{{ getCurrencySymbol(paymentData.currencyCode) }}</span>
                        <input
                          v-model="method.amount"
                          type="number"
                          step="0.01"
                          min="0"
                          class="form-input"
                          :placeholder="$t('APPLE_MESSAGES.PAYMENT.MODAL.SHIPPING_COST')"
                        />
                      </div>
                    </div>
                    <button
                      type="button"
                      class="remove-item-btn"
                      @click="removeShippingMethod(index)"
                    >
                      <i class="i-ph-x"></i>
                    </button>
                  </div>
                </div>

                <button
                  type="button"
                  class="add-item-btn"
                  @click="addShippingMethod"
                >
                  <i class="i-ph-plus mr-2"></i>
                  {{ $t('APPLE_MESSAGES.PAYMENT.MODAL.ADD_SHIPPING_METHOD') }}
                </button>
              </div>
            </div>

            <div class="form-section">
              <h3 class="section-title">
                {{ $t('APPLE_MESSAGES.PAYMENT.MODAL.CONTACT_REQUIREMENTS') }}
              </h3>

              <div class="checkbox-grid">
                <label class="checkbox-label">
                  <input
                    v-model="paymentData.requiresBilling"
                    type="checkbox"
                    class="checkbox"
                  >
                  <span class="checkmark"></span>
                  {{ $t('APPLE_MESSAGES.PAYMENT.MODAL.REQUIRE_BILLING') }}
                </label>

                <label class="checkbox-label">
                  <input
                    v-model="paymentData.requiresShipping"
                    type="checkbox"
                    class="checkbox"
                  >
                  <span class="checkmark"></span>
                  {{ $t('APPLE_MESSAGES.PAYMENT.MODAL.REQUIRE_SHIPPING_ADDRESS') }}
                </label>

                <label class="checkbox-label">
                  <input
                    v-model="paymentData.requiresEmail"
                    type="checkbox"
                    class="checkbox"
                  >
                  <span class="checkmark"></span>
                  {{ $t('APPLE_MESSAGES.PAYMENT.MODAL.REQUIRE_EMAIL') }}
                </label>

                <label class="checkbox-label">
                  <input
                    v-model="paymentData.requiresPhone"
                    type="checkbox"
                    class="checkbox"
                  >
                  <span class="checkmark"></span>
                  {{ $t('APPLE_MESSAGES.PAYMENT.MODAL.REQUIRE_PHONE') }}
                </label>
              </div>
            </div>
          </form>

          <div class="preview-section">
            <h3 class="section-title">
              {{ $t('APPLE_MESSAGES.PAYMENT.MODAL.PREVIEW') }}
            </h3>

            <div class="payment-preview">
              <ApplePayment
                :payment-request="previewPaymentRequest"
                :merchant-session="demoMerchantSession"
                :msp-id="mspId"
                :endpoints="demoEndpoints"
              />
            </div>
          </div>
        </div>
      </div>

      <div class="modal-footer">
        <button
          type="button"
          class="btn btn-secondary"
          @click="onClose"
        >
          {{ $t('APPLE_MESSAGES.PAYMENT.MODAL.CANCEL') }}
        </button>

        <button
          type="button"
          class="btn btn-primary"
          :disabled="!canCreateMessage"
          @click="createPaymentMessage"
        >
          {{ $t('APPLE_MESSAGES.PAYMENT.MODAL.CREATE_MESSAGE') }}
        </button>
      </div>
    </div>
  </woot-modal>
</template>

<script>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import ApplePayment from './ApplePayment.vue';

export default {
  components: {
    ApplePayment,
  },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    mspId: {
      type: String,
      required: true,
    },
    conversationId: {
      type: String,
      required: true,
    },
  },
  emits: ['close', 'create'],
  setup(props, { emit }) {
    const { t } = useI18n();

    const paymentData = ref({
      merchantName: '',
      currencyCode: 'USD',
      countryCode: 'US',
      lineItems: [
        { label: '', amount: '', type: 'final' }
      ],
      shippingMethods: [],
      requiresShipping: false,
      requiresBilling: true,
      requiresEmail: false,
      requiresPhone: false,
    });

    const previewPaymentRequest = computed(() => {
      return {
        country_code: paymentData.value.countryCode,
        currency_code: paymentData.value.currencyCode,
        supported_networks: ['visa', 'masterCard', 'amex'],
        merchant_capabilities: ['supports3DS', 'supportsDebit', 'supportsCredit'],
        line_items: paymentData.value.lineItems.filter(item => item.label && item.amount),
        total: {
          label: paymentData.value.merchantName || 'Total',
          amount: calculateTotal().toString(),
        },
        shipping_methods: paymentData.value.shippingMethods,
        required_billing_contact_fields: paymentData.value.requiresBilling ? ['postalAddress'] : [],
        required_shipping_contact_fields: paymentData.value.requiresShipping ? ['postalAddress', 'name'] : [],
      };
    });

    const demoMerchantSession = computed(() => ({
      merchantIdentifier: 'merchant.com.example.chatwoot',
      displayName: paymentData.value.merchantName || 'Demo Store',
      initiative: 'messaging',
    }));

    const demoEndpoints = computed(() => ({
      payment_gateway: `/apple_messages_for_business/${props.mspId}/payment_gateway/process_payment`,
      fallback_url: 'https://example.com/payment-fallback',
    }));

    const canCreateMessage = computed(() => {
      return paymentData.value.merchantName.trim().length > 0 &&
             paymentData.value.lineItems.some(item => item.label && item.amount > 0) &&
             calculateTotal() > 0;
    });

    const calculateTotal = () => {
      return paymentData.value.lineItems
        .filter(item => item.label && item.amount)
        .reduce((sum, item) => sum + parseFloat(item.amount || 0), 0);
    };

    const formatCurrency = (amount, currency) => {
      return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: currency || 'USD',
      }).format(parseFloat(amount || 0));
    };

    const getCurrencySymbol = (currency) => {
      const symbols = {
        USD: '$',
        EUR: '€',
        GBP: '£',
        CAD: 'C$',
        JPY: '¥',
      };
      return symbols[currency] || '$';
    };

    const addLineItem = () => {
      paymentData.value.lineItems.push({
        label: '',
        amount: '',
        type: 'final'
      });
    };

    const removeLineItem = (index) => {
      if (paymentData.value.lineItems.length > 1) {
        paymentData.value.lineItems.splice(index, 1);
      }
    };

    const addShippingMethod = () => {
      paymentData.value.shippingMethods.push({
        identifier: `shipping_${Date.now()}`,
        label: '',
        detail: '',
        amount: ''
      });
    };

    const removeShippingMethod = (index) => {
      paymentData.value.shippingMethods.splice(index, 1);
    };

    const createPaymentMessage = () => {
      if (!canCreateMessage.value) return;

      const messageData = {
        content_type: 'apple_pay',
        content_data: {
          payment_request: {
            country_code: paymentData.value.countryCode,
            currency_code: paymentData.value.currencyCode,
            supported_networks: ['visa', 'masterCard', 'amex', 'discover'],
            merchant_identifier: `merchant.${paymentData.value.merchantName.toLowerCase().replace(/\s+/g, '.')}`,
            merchant_capabilities: ['supports3DS', 'supportsDebit', 'supportsCredit'],
            line_items: paymentData.value.lineItems
              .filter(item => item.label && item.amount)
              .map(item => ({
                label: item.label,
                amount: parseFloat(item.amount).toFixed(2),
                type: 'final'
              })),
            total: {
              label: paymentData.value.merchantName,
              amount: calculateTotal().toFixed(2),
              type: 'final'
            },
            shipping_methods: paymentData.value.shippingMethods
              .filter(method => method.label && method.amount)
              .map(method => ({
                identifier: method.identifier,
                label: method.label,
                detail: method.detail,
                amount: parseFloat(method.amount).toFixed(2)
              })),
            required_billing_contact_fields: buildContactFields('billing'),
            required_shipping_contact_fields: buildContactFields('shipping'),
          },
          endpoints: {
            payment_gateway: `/apple_messages_for_business/${props.mspId}/payment_gateway/process_payment`,
            method_update: `/apple_messages_for_business/${props.mspId}/payment_gateway/method_update`,
            fallback_url: `${window.location.origin}/payment-fallback`,
          }
        },
      };

      emit('create', messageData);
      onClose();
    };

    const buildContactFields = (type) => {
      const fields = ['postalAddress'];

      if (type === 'billing' && paymentData.value.requiresBilling) {
        if (paymentData.value.requiresEmail) fields.push('emailAddress');
        if (paymentData.value.requiresPhone) fields.push('phoneNumber');
      }

      if (type === 'shipping' && paymentData.value.requiresShipping) {
        fields.push('name');
        if (paymentData.value.requiresPhone) fields.push('phoneNumber');
      }

      return fields;
    };

    const onClose = () => {
      // Reset form
      paymentData.value = {
        merchantName: '',
        currencyCode: 'USD',
        countryCode: 'US',
        lineItems: [{ label: '', amount: '', type: 'final' }],
        shippingMethods: [],
        requiresShipping: false,
        requiresBilling: true,
        requiresEmail: false,
        requiresPhone: false,
      };

      emit('close');
    };

    // Watch for show prop changes to reset form
    watch(() => props.show, (newShow) => {
      if (!newShow) {
        setTimeout(onClose, 300);
      }
    });

    return {
      paymentData,
      previewPaymentRequest,
      demoMerchantSession,
      demoEndpoints,
      canCreateMessage,
      calculateTotal,
      formatCurrency,
      getCurrencySymbol,
      addLineItem,
      removeLineItem,
      addShippingMethod,
      removeShippingMethod,
      createPaymentMessage,
      onClose,
    };
  },
};
</script>

<style scoped>
.apple-payment-modal {
  @apply w-full max-w-6xl;
}

.modal-header {
  @apply pb-6 border-b border-gray-200;
}

.modal-title {
  @apply text-2xl font-bold text-gray-900 mb-2;
}

.modal-description {
  @apply text-gray-600;
}

.modal-content {
  @apply py-6;
}

.payment-setup {
  @apply grid grid-cols-1 lg:grid-cols-2 gap-8;
}

.payment-form {
  @apply space-y-6;
}

.form-section {
  @apply space-y-4;
}

.section-title {
  @apply text-lg font-semibold text-gray-900 mb-4;
}

.form-row {
  @apply flex space-x-4;
}

.form-group {
  @apply space-y-2;
}

.form-group.flex-1 {
  @apply flex-1;
}

.form-group.flex-2 {
  @apply flex-2;
}

.form-label {
  @apply block text-sm font-medium text-gray-700;
}

.form-input {
  @apply w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500;
}

.form-select {
  @apply w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white;
}

.input-group {
  @apply flex;
}

.input-prefix {
  @apply px-3 py-3 bg-gray-50 border border-r-0 border-gray-300 rounded-l-lg text-gray-500 font-medium;
}

.input-group .form-input {
  @apply rounded-l-none border-l-0 focus:border-l focus:border-blue-500;
}

.line-items-container {
  @apply space-y-4;
}

.line-item {
  @apply bg-gray-50 p-4 rounded-lg;
}

.shipping-method {
  @apply bg-blue-50 p-4 rounded-lg;
}

.remove-item-btn {
  @apply w-10 h-10 bg-red-100 text-red-600 rounded-lg hover:bg-red-200 transition-colors duration-200 flex items-center justify-center flex-shrink-0 mt-6;
}

.add-item-btn {
  @apply w-full p-3 border-2 border-dashed border-gray-300 rounded-lg text-gray-600 hover:border-blue-300 hover:text-blue-600 transition-colors duration-200 flex items-center justify-center;
}

.total-section {
  @apply border-t border-gray-200 pt-4 mt-4;
}

.total-row {
  @apply flex justify-between items-center text-lg font-bold;
}

.total-label {
  @apply text-gray-900;
}

.total-amount {
  @apply text-green-600;
}

.checkbox-group {
  @apply space-y-3;
}

.checkbox-grid {
  @apply grid grid-cols-1 sm:grid-cols-2 gap-3;
}

.checkbox-label {
  @apply flex items-center space-x-3 cursor-pointer;
}

.checkbox {
  @apply w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500;
}

.checkmark {
  @apply text-sm text-gray-700;
}

.shipping-methods {
  @apply space-y-4;
}

.preview-section {
  @apply space-y-4;
}

.payment-preview {
  @apply bg-gray-50 border border-gray-200 rounded-lg p-6;
}

.modal-footer {
  @apply pt-6 border-t border-gray-200 flex justify-end space-x-4;
}

.btn {
  @apply px-6 py-2 rounded-lg font-medium transition-colors duration-200;
}

.btn-secondary {
  @apply bg-gray-100 text-gray-700 hover:bg-gray-200;
}

.btn-primary {
  @apply bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed;
}
</style>