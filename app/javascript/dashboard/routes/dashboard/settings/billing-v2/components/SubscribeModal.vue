<script setup>
import { ref, computed } from 'vue';
import Modal from 'dashboard/components/Modal.vue';
import ButtonV4 from 'next/button/Button.vue';

const props = defineProps({
  plan: {
    type: Object,
    required: true,
  },
  currentQuantity: {
    type: Number,
    default: 0,
  },
  isSubscribing: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close', 'subscribe']);

const show = ref(true);
const quantity = ref(props.plan?.min_seats || 1);

const minSeats = computed(() => props.plan?.min_seats || 1);
const maxSeats = computed(() => props.plan?.max_seats || 999);

const totalPrice = computed(() => {
  return (props.plan?.base_price || 0) * quantity.value;
});

const totalCredits = computed(() => {
  // Credits are constant per plan, not multiplied by seats
  return props.plan?.included_credits || 0;
});

const formatPrice = price => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  }).format(price);
};

const formatNumber = num => {
  return new Intl.NumberFormat('en-US').format(num);
};

const incrementQuantity = () => {
  if (quantity.value < maxSeats.value) {
    quantity.value += 1;
  }
};

const decrementQuantity = () => {
  if (quantity.value > minSeats.value) {
    quantity.value -= 1;
  }
};

const handleSubscribe = () => {
  emit('subscribe', {
    pricing_plan_id: props.plan.id,
    quantity: quantity.value,
  });
};

const close = () => {
  show.value = false;
  emit('close');
};
</script>

<template>
  <Modal v-model:show="show" :on-close="close">
    <div class="flex flex-col h-auto overflow-auto">
      <div class="w-full px-5 py-4 border-b border-n-weak">
        <h3 class="text-lg font-semibold text-n-800">
          {{ $t('BILLING_SETTINGS_V2.SUBSCRIBE_MODAL.TITLE') }}
        </h3>
      </div>

      <div class="p-5 space-y-4">
        <!-- Plan Info -->
        <div class="p-4 bg-n-25 rounded-lg">
          <h4 class="font-semibold text-n-800">{{ plan.name }}</h4>
          <p class="mt-1 text-sm text-n-600">{{ plan.description }}</p>
        </div>

        <!-- Quantity Selector -->
        <div>
          <label class="block mb-2 text-sm font-medium text-n-700">
            {{ $t('BILLING_SETTINGS_V2.SUBSCRIBE_MODAL.NUMBER_OF_SEATS') }}
          </label>
          <div class="flex items-center gap-3">
            <ButtonV4
              sm
              faded
              slate
              icon="i-lucide-minus"
              :disabled="quantity <= minSeats"
              @click="decrementQuantity"
            />
            <input
              v-model.number="quantity"
              type="number"
              :min="minSeats"
              :max="maxSeats"
              class="w-20 px-3 py-2 text-center border border-n-weak rounded-lg focus:outline-none focus:ring-2 focus:ring-b-500"
            />
            <ButtonV4
              sm
              faded
              slate
              icon="i-lucide-plus"
              :disabled="quantity >= maxSeats"
              @click="incrementQuantity"
            />
          </div>
          <p class="mt-1 text-xs text-n-600">
            {{ $t('BILLING_SETTINGS_V2.SUBSCRIBE_MODAL.MIN') }}: {{ minSeats }}
            -
            {{ $t('BILLING_SETTINGS_V2.SUBSCRIBE_MODAL.MAX') }}: {{ maxSeats }}
          </p>
        </div>

        <!-- Summary -->
        <div class="p-4 bg-b-50 rounded-lg space-y-2">
          <div class="flex justify-between text-sm">
            <span class="text-n-700">{{
              $t('BILLING_SETTINGS_V2.SUBSCRIBE_MODAL.BASE_PRICE')
            }}</span>
            <span class="font-semibold text-n-800">
              {{ formatPrice(plan.base_price) }} ×
              {{ quantity }}
            </span>
          </div>
          <div class="flex justify-between text-sm">
            <span class="text-n-700">{{
              $t('BILLING_SETTINGS_V2.SUBSCRIBE_MODAL.INCLUDED_CREDITS')
            }}</span>
            <span class="font-semibold text-g-800">
              {{ formatNumber(totalCredits) }}
              {{ $t('BILLING_SETTINGS_V2.SUBSCRIBE_MODAL.CREDITS') }}
            </span>
          </div>
          <div class="flex justify-between text-sm pt-2 border-t border-b-200">
            <span class="font-semibold text-n-800">{{
              $t('BILLING_SETTINGS_V2.SUBSCRIBE_MODAL.MONTHLY_TOTAL')
            }}</span>
            <span class="text-lg font-bold text-b-800">
              {{ formatPrice(totalPrice) }}
            </span>
          </div>
        </div>
      </div>

      <div class="flex justify-end gap-2 px-5 py-4 border-t border-n-weak">
        <ButtonV4 sm faded slate :disabled="isSubscribing" @click="close">
          {{ $t('BILLING_SETTINGS_V2.SUBSCRIBE_MODAL.CANCEL') }}
        </ButtonV4>
        <ButtonV4
          sm
          solid
          blue
          :is-loading="isSubscribing"
          @click="handleSubscribe"
        >
          {{ $t('BILLING_SETTINGS_V2.SUBSCRIBE_MODAL.CONFIRM') }}
        </ButtonV4>
      </div>
    </div>
  </Modal>
</template>
