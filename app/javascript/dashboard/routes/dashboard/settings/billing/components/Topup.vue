<script setup>
import { ref, computed } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import WootSubmitButton from 'dashboard/components/buttons/FormSubmitButton.vue';
// import Auth from '../../../../api/auth';
import wootConstants from 'dashboard/constants/globals';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  topupType: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['close']);

const { AVAILABILITY_STATUS_KEYS } = wootConstants;

const store = useStore();
const { t } = useI18n();

const packageId = ref(props.id);
const topupType = ref(props.topupType);
const subscriptionId = ref(props.id);
const amount = ref(0);
const total = ref(0);
const selectedMethod = ref('M2');
const isSubmitting = ref(false);

const rules = {};

const v$ = useVuelidate(rules, {});

const pageTitle = computed(() => t('PAYMENT.ADD_TOPUP_TITLE', {
  topupType: t(`PAYMENT.TOPUP_${props.topupType}`),
}));

const updateTotal = () => {
  // block_size = 1000

  //   case type
  //   when 'max_active_users'
  //     block_price = 150_000
  //   when 'ai_responses'
  //     block_size = 5000
  //     block_price = 150_000
  //   else
  //     return 0
  //   end
  let blockSize = 1000;
  let perBlock = 150000;

  if (topupType.value == 'ai_responses') {
    blockSize = 5000;
    perBlock = 150000;
  }
  const blocks = Math.ceil(amount.value / blockSize);
  total.value = blocks * perBlock;
};

const editAgent = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;
};

// Fixed submit function based on actual response structure
const submit = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  isSubmitting.value = true;

  try {
    console.log('props', props);
    const payload = {
      id: Date.now(),
      topup_type: topupType.value,
      user_id: 11,
      payment_method: selectedMethod.value || 'M2',
      subscription_id: subscriptionId.value,
      amount: amount.value,
    };

    const response = await store.dispatch('createTopup', payload);
    console.log('Response received:', response);

    // Handle exact response structure we now know
    if (response && response.payment_url) {
      const paymentUrl = response.payment_url;
      console.log('Redirecting to:', paymentUrl);

      // Force redirect using direct window.location assignment
      window.location.href = paymentUrl;

      // If the above doesn't work, try these alternative approaches:
      // setTimeout(() => { window.location.href = paymentUrl; }, 100);
      // window.open(paymentUrl, '_self');
    } else {
      console.warn('Payment URL not found in response:', response);
      useAlert('Berhasil membuat langganan, tetapi tidak ada URL pembayaran.');
      emit('close');
    }
  } catch (error) {
    console.error('Error creating subscription:', error);
    useAlert('Gagal membuat langganan: ' + (error.message || ''));
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header :header-title="pageTitle" />

    <form class="w-full" @submit.prevent="editAgent">
      <!-- Total -->
      <div class="w-full mt-4">
        <label class="block text-sm font-medium text-slate-700">
          Enter Topup Amount
        </label>
        <input
          v-model.number="amount"
          type="number"
          class="w-full border border-slate-300 rounded-md px-3 py-2"
          :min="topupType === 'ai_responses' ? 5000 : 1000"
          :step="topupType === 'ai_responses' ? 5000 : 1000"
          @input="updateTotal"
          @keydown.prevent
        />
      </div>

      <div class="w-full">
        <p class="text-sm text-slate-500">
          Total: <strong>Rp {{ total }}</strong>
        </p>
      </div>

      <!-- Tombol -->
      <div class="w-full mt-6">
        <button
          type="button"
          :disabled="v$.$invalid || isSubmitting"
          class="bg-primary-600 text-white w-full py-2 rounded font-semibold flex items-center justify-center"
          @click="submit"
        >
          <span v-if="isSubmitting" class="mr-2">
            <!-- Simple loading spinner -->
            <svg
              class="animate-spin h-5 w-5 text-white"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
            >
              <circle
                class="opacity-25"
                cx="12"
                cy="12"
                r="10"
                stroke="currentColor"
                stroke-width="4"
              />
              <path
                class="opacity-75"
                fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
              />
            </svg>
          </span>
          {{ isSubmitting ? 'Processing...' : 'Continue' }}
        </button>
      </div>
    </form>
  </div>
</template>
