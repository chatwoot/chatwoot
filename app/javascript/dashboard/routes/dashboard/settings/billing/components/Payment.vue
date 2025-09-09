<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import WootSubmitButton from 'dashboard/components/buttons/FormSubmitButton.vue';
import wootConstants from 'dashboard/constants/globals';
import PaymentVoucherInput from './PaymentVoucherInput.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { calculatePackagePrice } from '../pricing-utils';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  name: {
    type: String,
    required: true,
  },
  plan: {
    type: Object,
    required: true,
  },
  plans: {
    type: Array,
    required: true,
  },
  duration: {
    type: String,
    required: true,
  },
  qty: {
    type: Number,
    required: true,
  },
  billingCycleTabs: {
    type: Array,
    required: true,
  },
});

const emit = defineEmits(['close']);

const { AVAILABILITY_STATUS_KEYS } = wootConstants;

const store = useStore();
const { t } = useI18n();

const packageId = ref(props.id);
const packageName = ref(props.name);
const selectedVoucher = ref(undefined)
const selectedVoucherType = computed(() => {
  const voucherType = selectedVoucher.value?.voucher?.voucher?.discount_type
  if (voucherType === 'idr') {
    return 'IDR'
  } else if (voucherType === 'percentage') {
    return '%'
  }
  return voucherType
})
const selectedMethod = ref('VC');
const selectedPlan = ref(props.plan);
const plans = ref(props.plans);
const isSubmitting = ref(false);
const isValidatingVoucher = ref(false);

// Tambahan untuk custom dropdown
const isDropdownOpen = ref(false);
const dropdownRef = ref(null);
const selectedBillingCycle = ref(props.billingCycleTabs[0]); // Default ke opsi pertama

watch(() => props.duration, duration => {
  selectedBillingCycle.value = props.billingCycleTabs.find(e => e.id === duration)
}, {
  immediate: true,
})

const selectedPlanMonthlyPrice = computed(() => selectedPlan.value.monthly_price)

// Kalkulasi total harga berdasarkan siklus penagihan
const totalPrice = computed(() => {
  return calculatePackagePrice(
    selectedPlanMonthlyPrice.value,
    selectedPlan.value.name,
    selectedBillingCycle.value.qty
  );
});

// Fungsi untuk handle klik di luar dropdown
const handleClickOutside = event => {
  if (dropdownRef.value && !dropdownRef.value.contains(event.target)) {
    isDropdownOpen.value = false;
  }
};

// Tambahkan event listener saat komponen di-mount
onMounted(() => {
  document.addEventListener('click', handleClickOutside);
});

// Hapus event listener saat komponen di-unmount
onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside);
});

const selectBillingCycle = cycle => {
  selectedBillingCycle.value = cycle;
  isDropdownOpen.value = false;
};

const rules = {
  packageName: { required, minLength: minLength(1) },
};

const v$ = useVuelidate(rules, {
  packageName,
});

const uiFlags = useMapGetter('agents/getUIFlags');
const getCustomRoles = useMapGetter('customRole/getCustomRoles');

const submit = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  isSubmitting.value = true;

  let errorMessage = '';
  try {
    const payload = {
      id: Date.now(),
      name: packageName.value,
      status: 'active',
      plan_id: selectedPlan.value.id,
      user_id: 11,
      payment_method: selectedMethod.value || 'M2',
      billing_cycle: selectedBillingCycle.value.id,
      qty: selectedBillingCycle.value.qty,
      voucher_code: selectedVoucher.value?.voucher?.voucher?.name || undefined,
    };

    const response = await store.dispatch('createSubscription', payload);
    console.log('Response received:', response);

    if (
      response &&
      response.subscription_payment &&
      response.subscription_payment.payment_url
    ) {
      const paymentUrl = response.subscription_payment.payment_url;
      console.log('Redirecting to:', paymentUrl);

      window.location.href = paymentUrl;
    } 
    else {
      useAlert(response?.response?.data?.errors || 'Gagal membuat langganan. Silakan coba lagi.');
      emit('close');
    }
  } catch (error) {
    useAlert('Gagal membuat langganan: ' + (error?.response?.data?.errors || ''));
    console.error('Gagal membuat langganan:', error);
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header :header-title="t('PAYMENT.CHOOSE_PAYMENT_TITLE')" />

    <form class="w-full" @submit.prevent="submit">
      <div class="w-full">
        <!-- Pilihan metode -->
        <div class="flex gap-3">
          <div
            class="w-full border rounded-lg p-4 flex flex-col items-start cursor-pointer border-transparent"
            :class="{ '!border-primary-500': selectedMethod === 'VC' }"
            @click.prevent="selectedMethod = 'VC'"
          >
            <div class="text-sm font-medium">{{ t('PAYMENT.CC_SUBS.NAME') }}</div>
            <div class="text-xs text-slate-500">
              {{ t('PAYMENT.CC_SUBS.DESC') }}
            </div>
          </div>
          <div
            class="w-full border rounded-lg p-4 flex flex-col items-start cursor-pointer border-transparent"
            :class="{ '!border-primary-500': selectedMethod === 'M2' }"
            @click.prevent="selectedMethod = 'M2'"
          >
            <div class="text-sm font-medium">{{ t('PAYMENT.VA_MANDIRI.NAME') }}</div>
            <div class="text-xs text-slate-500">
              {{ t('PAYMENT.VA_MANDIRI.DESC') }}
            </div>
          </div>
        </div>
      </div>

      <!-- Custom Dropdown Paket -->
      <div ref="dropdownRef" class="w-full mt-4 relative">
        <div
          class="border rounded p-3 flex justify-between items-center cursor-pointer"
          @click="() => {
            if (isValidatingVoucher) {
              return
            }
            isDropdownOpen = !isDropdownOpen
          }"
        >
          <div>{{ selectedBillingCycle.name }}</div>
          <div class="font-medium mr-8">{{ totalPrice.toLocaleString() }} IDR</div>

          <!-- Dropdown arrow -->
          <div class="absolute top-0 right-0 px-4 py-4 transform duration-300"
            :class="isDropdownOpen ? '-rotate-180' : 'rotate-0'">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-4 w-4"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M19 9l-7 7-7-7"
              />
            </svg>
          </div>
        </div>

        <!-- Dropdown menu -->
        <div
          v-if="isDropdownOpen"
          class="absolute z-50 left-0 right-0 bg-white dark:bg-n-slate-2 border rounded mt-1 shadow-lg max-h-60 overflow-auto"
          style="min-width: 100%"
        >
          <div
            v-for="cycle in props.billingCycleTabs"
            :key="cycle.id"
            class="p-3 hover:bg-gray-100 cursor-pointer flex justify-between items-center relative"
            @click="selectBillingCycle(cycle)"
          >
            <div class="flex items-center">
              {{ cycle.name }}
              <span
                v-if="cycle.badge"
                class="ml-2 bg-blue-500 text-white text-xs px-2 py-0.5 rounded-full"
              >
                {{ cycle.badge }}
              </span>
            </div>
            <div class="font-medium">
              {{ calculatePackagePrice(selectedPlanMonthlyPrice, selectedPlan.name, cycle.qty).toLocaleString() }}
              IDR
            </div>
          </div>
        </div>
      </div>

      <PaymentVoucherInput :subscriptionPlanId="selectedPlan?.id" :selectedPrice="totalPrice" v-model="selectedVoucher" v-model:is-validating-voucher="isValidatingVoucher"/>

      <!-- Total -->
       <div class="flex flex-row justify-end mt-3">
         <Spinner class="mr-10" v-if="isValidatingVoucher"/>
         <div v-else class="flex flex-col gap-1">
          <div class="flex flex-row gap-4">
            <div class="flex-1 text-right flex flex-col gap-1">
              <span>{{ $t('BILLING.SUB_TOTAL') }}</span>
              <span>{{ $t('BILLING.DISCOUNT_LBL') }}</span>
              <span>{{ $t('BILLING.Total_PAY') }}</span>
            </div>
            <div class="font-semibold text-right flex flex-col gap-1">
              <span>{{ totalPrice.toLocaleString() }} IDR</span>
              <span>{{ selectedVoucher?.voucher?.voucher?.discount_value?.toLocaleString() || 0 }} {{ selectedVoucherType }}</span>
              <span>{{ (selectedVoucher?.new_price || totalPrice).toLocaleString() || 0 }} IDR</span>
            </div>
          </div>
         </div>
       </div>

      <!-- Info tambahan -->
      <div class="w-full mt-4">
        <div class="bg-sky-50 text-sky-700 text-sm p-3 rounded">
          <span class="mr-2">👁️</span>
          {{ t('PAYMENT.BUY_DESC', {
            qty: selectedBillingCycle.qty,
          }) }}
          <strong>{{
            new Date(
              Date.now() + selectedBillingCycle.qty * 30 * 24 * 60 * 60 * 1000
            ).toLocaleDateString()
          }}</strong>
        </div>
      </div>

      <!-- Tombol -->
      <div class="w-full mt-6">
        <woot-button :is-loading="isSubmitting"
          :size="'expanded'" class="w-full" :disabled="v$.$invalid || isSubmitting">
            {{ isSubmitting ? $t('PAYMENT.PROCESSING') : $t('PAYMENT.CONTINUE') }}
          </woot-button>
      </div>
    </form>
  </div>
</template>
