<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minValue, numeric } from '@vuelidate/validators';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    isSubmitting: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['cancel', 'update:show', 'submit'],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      amount: '',
      currency: 'KWD',
      currencies: [
        { value: 'KWD', label: 'KWD - Kuwaiti Dinar' },
        { value: 'USD', label: 'USD - US Dollar' },
        { value: 'SAR', label: 'SAR - Saudi Riyal' },
        { value: 'AED', label: 'AED - UAE Dirham' },
        { value: 'EUR', label: 'EUR - Euro' },
        { value: 'GBP', label: 'GBP - British Pound' },
      ],
    };
  },
  validations: {
    amount: {
      required,
      numeric,
      minValue: minValue(0.01),
    },
    currency: {
      required,
    },
  },
  computed: {
    localShow: {
      get() {
        return this.show;
      },
      set(value) {
        this.$emit('update:show', value);
      },
    },
    isFormValid() {
      return (
        !!this.amount &&
        !this.v$.amount.$error &&
        !!this.currency &&
        !this.v$.currency.$error
      );
    },
  },
  methods: {
    onCancel() {
      this.resetForm();
      this.$emit('cancel');
    },
    onSubmit() {
      this.v$.$touch();
      if (!this.isFormValid) {
        return;
      }

      const paymentData = {
        amount: parseFloat(this.amount),
        currency: this.currency,
      };

      this.$emit('submit', paymentData);
    },
    resetForm() {
      this.amount = '';
      this.currency = 'KWD';
      this.v$.$reset();
    },
  },
};
</script>

<template>
  <woot-modal v-model:show="localShow" :on-close="onCancel">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header
        :header-title="$t('PAYMENT_LINK.TITLE')"
        :header-content="$t('PAYMENT_LINK.DESC')"
      />
      <form
        class="w-full modal-content pt-2 px-8 pb-8"
        @submit.prevent="onSubmit"
      >
        <div class="flex items-center mt-4 gap-2">
          <!-- Amount Input -->
          <div class="w-full">
            <label :class="{ error: v$.amount.$error }">
              {{ $t('PAYMENT_LINK.FORM.AMOUNT.LABEL') }}
              <input
                v-model="amount"
                type="number"
                step="0.01"
                min="0.01"
                :placeholder="$t('PAYMENT_LINK.FORM.AMOUNT.PLACEHOLDER')"
                @input="v$.amount.$touch"
              />
              <span v-if="v$.amount.$error" class="message">
                {{ $t('PAYMENT_LINK.FORM.AMOUNT.ERROR') }}
              </span>
            </label>
          </div>

          <!-- Currency Dropdown -->
          <div class="w-full">
            <label :class="{ error: v$.currency.$error }">
              {{ $t('PAYMENT_LINK.FORM.CURRENCY.LABEL') }}
              <select v-model="currency" @change="v$.currency.$touch">
                <option
                  v-for="curr in currencies"
                  :key="curr.value"
                  :value="curr.value"
                >
                  {{ curr.label }}
                </option>
              </select>
              <span v-if="v$.currency.$error" class="message">
                {{ $t('PAYMENT_LINK.FORM.CURRENCY.ERROR') }}
              </span>
            </label>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="flex flex-row justify-end w-full gap-2 px-0 py-2 mt-6">
          <NextButton
            faded
            slate
            type="reset"
            :label="$t('PAYMENT_LINK.CANCEL')"
            :disabled="isSubmitting"
            @click.prevent="onCancel"
          />
          <NextButton
            type="submit"
            :label="$t('PAYMENT_LINK.SUBMIT')"
            :disabled="!isFormValid || isSubmitting"
            :loading="isSubmitting"
          />
        </div>
      </form>
    </div>
  </woot-modal>
</template>
