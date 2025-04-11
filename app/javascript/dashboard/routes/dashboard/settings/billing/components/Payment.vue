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

const rules = {
  packageName: { required, minLength: minLength(1) },
};

const v$ = useVuelidate(rules, {
  packageName,
});

const pageTitle = computed(
  () => 'Pilih Metode Pembayaran'
);

const uiFlags = useMapGetter('agents/getUIFlags');
const getCustomRoles = useMapGetter('customRole/getCustomRoles');

const roles = computed(() => {
  const defaultRoles = [
    {
      id: 'administrator',
      name: 'administrator',
      label: t('AGENT_MGMT.AGENT_TYPES.ADMINISTRATOR'),
    },
    {
      id: 'agent',
      name: 'agent',
      label: t('AGENT_MGMT.AGENT_TYPES.AGENT'),
    },
  ];

  const customRoles = getCustomRoles.value.map(role => ({
    id: role.id,
    name: `custom_${role.id}`,
    label: role.name,
  }));

  return [...defaultRoles, ...customRoles];
});

const selectedRole = computed(() =>
  roles.value.find(
    role =>
      role.id === selectedRoleId.value || role.name === selectedRoleId.value
  )
);

const editAgent = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  try {
    const payload = {
      id: props.id,
      name: packageName.value,
      availability: agentAvailability.value,
    };

    if (selectedRole.value.name.startsWith('custom_')) {
      payload.custom_role_id = selectedRole.value.id;
    } else {
      payload.role = selectedRole.value.name;
      payload.custom_role_id = null;
    }

    await store.dispatch('agents/updatex', payload);
    useAlert(t('AGENT_MGMT.EDIT.API.SUCCESS_MESSAGE'));
    emit('close');
  } catch (error) {
    useAlert(t('AGENT_MGMT.EDIT.API.ERROR_MESSAGE'));
  }
};

// Fixed submit function based on actual response structure
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
      payment_method: selectedMethod.value || 'M2'
    };
    
    const response = await store.dispatch('createSubscription', payload);
    console.log('Response received:', response);
    
    // Handle exact response structure we now know
    if (response && response.subscription_payment && response.subscription_payment.payment_url) {
      const paymentUrl = response.subscription_payment.payment_url;
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
      <div class="w-full">
        <!-- Pilihan metode -->
        <div class="flex gap-3">
          <button
            class="w-full border rounded-lg p-4 flex flex-col items-start"
            :class="{ 'border-primary-500': selectedMethod === 'VC' }"
            @click.prevent="selectedMethod = 'VC'"
          >
            <div class="text-sm font-medium">Kartu Kredit (Berlangganan)</div>
            <div class="text-xs text-slate-500">Nikmati perpanjangan otomatis</div>
          </button>
          <button
            class="w-full border rounded-lg p-4 flex flex-col items-start"
            :class="{ 'border-primary-500': selectedMethod === 'M2' }"
            @click.prevent="selectedMethod = 'M2'"
          >
            <div class="text-sm font-medium">VA - MANDIRI</div>
            <div class="text-xs text-slate-500">Bayar sekali dan topup sesuai kebutuhan</div>
          </button>
        </div>
      </div>

      <!-- Dropdown Paket -->
      <div class="w-full mt-4">
        <div class="relative">
          <select
            v-model="selectedPlan"
            class="w-full border rounded p-3"
          >
            <option v-for="plan in plans" :key="plan.id" :value="plan">
              {{ plan.name }}
            </option>
          </select>
  
          <div class="absolute top-0 right-0 px-4 py-3 pointer-events-none">
            {{ selectedPlan.monthly_price }} IDR
          </div>
        </div>
      </div>
      
      <!-- Total -->
      <div class="w-full mt-4">
        <div class="text-right font-semibold">
          Total Payment<br />
          {{ selectedPlan.monthly_price.toLocaleString() }} IDR
        </div>
      </div>

      <!-- Info tambahan -->
      <div class="w-full mt-4">
        <div class="bg-sky-50 text-sky-700 text-sm p-3 rounded">
          <span class="mr-2">👁️</span>
          Beli paket pro akan aktif selama bulan, dari hari ini sampai
          <strong>--</strong>
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
            <svg class="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
          </span>
          {{ isSubmitting ? 'Processing...' : 'Continue' }}
        </button>
      </div>
    </form>
  </div>
</template>