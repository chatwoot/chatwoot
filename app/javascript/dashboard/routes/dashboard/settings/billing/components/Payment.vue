<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import WootSubmitButton from 'dashboard/components/buttons/FormSubmitButton.vue';
import wootConstants from 'dashboard/constants/globals';

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
const selectedMethod = ref('VC');
const selectedPlan = ref(props.plan);
const plans = ref(props.plans);
const isSubmitting = ref(false);

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
  return selectedBillingCycle.value.qty * selectedPlanMonthlyPrice.value;
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

const pageTitle = computed(() => 'Pilih Metode Pembayaran');

const uiFlags = useMapGetter('agents/getUIFlags');
const getCustomRoles = useMapGetter('customRole/getCustomRoles');

const submit = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  isSubmitting.value = true;

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

    <form class="w-full" @submit.prevent="submit">
      <div class="w-full">
        <!-- Pilihan metode -->
        <div class="flex gap-3">
          <button
            class="w-full border rounded-lg p-4 flex flex-col items-start"
            :class="{ 'border-primary-500': selectedMethod === 'VC' }"
            @click.prevent="selectedMethod = 'VC'"
          >
            <div class="text-sm font-medium">Kartu Kredit (Berlangganan)</div>
            <div class="text-xs text-slate-500">
              Nikmati perpanjangan otomatis
            </div>
          </button>
          <button
            class="w-full border rounded-lg p-4 flex flex-col items-start"
            :class="{ 'border-primary-500': selectedMethod === 'M2' }"
            @click.prevent="selectedMethod = 'M2'"
          >
            <div class="text-sm font-medium">VA - MANDIRI</div>
            <div class="text-xs text-slate-500">
              Bayar sekali dan topup sesuai kebutuhan
            </div>
          </button>
        </div>
      </div>

      <!-- Custom Dropdown Paket -->
      <div ref="dropdownRef" class="w-full mt-4 relative">
        <div
          class="border rounded p-3 flex justify-between items-center cursor-pointer"
          @click="isDropdownOpen = !isDropdownOpen"
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
          class="absolute z-50 left-0 right-0 bg-white border rounded mt-1 shadow-lg max-h-60 overflow-auto"
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
              {{ (cycle.qty * selectedPlanMonthlyPrice).toLocaleString() }}
              IDR
            </div>
          </div>
        </div>
      </div>

      <!-- Total -->
      <div class="w-full mt-4">
        <div class="text-right font-semibold">
          Total Payment<br />
          {{ totalPrice.toLocaleString() }} IDR
        </div>
      </div>

      <!-- Info tambahan -->
      <div class="w-full mt-4">
        <div class="bg-sky-50 text-sky-700 text-sm p-3 rounded">
          <span class="mr-2">👁️</span>
          Beli paket pro akan aktif selama {{ selectedBillingCycle.qty }} bulan,
          dari hari ini sampai
          <strong>{{
            new Date(
              Date.now() + selectedBillingCycle.qty * 30 * 24 * 60 * 60 * 1000
            ).toLocaleDateString()
          }}</strong>
        </div>
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
