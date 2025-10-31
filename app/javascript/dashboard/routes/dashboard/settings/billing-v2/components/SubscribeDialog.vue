<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  plan: {
    type: Object,
    default: null,
  },
  isSubscribing: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['subscribe']);

const { t } = useI18n();

const dialogRef = ref(null);
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

defineExpose({
  dialogRef,
});
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    width="xl"
    :title="t('BILLING_SETTINGS_V2.SUBSCRIBE_MODAL.TITLE')"
    :confirm-button-label="t('BILLING_SETTINGS_V2.SUBSCRIBE_MODAL.CONFIRM')"
    :cancel-button-label="t('BILLING_SETTINGS_V2.SUBSCRIBE_MODAL.CANCEL')"
    :is-loading="isSubscribing"
    @confirm="handleSubscribe"
  >
    <div v-if="plan" class="space-y-4">
      <!-- Plan Info -->
      <div class="p-4 rounded-lg bg-n-slate-2 dark:bg-n-solid-2">
        <h4 class="font-semibold text-n-slate-12">{{ plan.name }}</h4>
        <p class="mt-1 text-sm text-n-slate-11">{{ plan.description }}</p>
      </div>

      <!-- Quantity Selector -->
      <div
        class="p-4 rounded-lg bg-n-slate-2 dark:bg-n-solid-2 border border-n-slate-4 dark:border-n-solid-4"
      >
        <div class="flex items-center justify-between mb-3">
          <div>
            <label class="block text-sm font-semibold text-n-slate-12">
              {{ t('BILLING_SETTINGS_V2.SUBSCRIBE_MODAL.NUMBER_OF_SEATS') }}
            </label>
            <p class="mt-0.5 text-xs text-n-slate-11">
              {{ t('BILLING_SETTINGS_V2.SUBSCRIBE_MODAL.MIN') }}:
              {{ minSeats }} •
              {{ t('BILLING_SETTINGS_V2.SUBSCRIBE_MODAL.MAX') }}:
              {{ maxSeats }}
            </p>
          </div>
          <div class="flex items-center gap-2">
            <Button
              type="button"
              variant="faded"
              color="slate"
              size="sm"
              icon="i-lucide-minus"
              :disabled="quantity <= minSeats"
              @click="decrementQuantity"
            />
            <div class="relative">
              <Input
                v-model="quantity"
                type="number"
                :min="String(minSeats)"
                :max="String(maxSeats)"
                custom-input-class="w-16 text-center font-semibold text-base"
                size="sm"
              />
            </div>
            <Button
              type="button"
              variant="faded"
              color="slate"
              size="sm"
              icon="i-lucide-plus"
              :disabled="quantity >= maxSeats"
              @click="incrementQuantity"
            />
          </div>
        </div>
        <div class="flex items-center gap-2 text-xs text-n-slate-11">
          <span class="inline-flex items-center gap-1">
            <span class="w-1 h-1 rounded-full bg-n-blue-9" />
            {{ formatPrice(plan.base_price) }}
            {{ t('BILLING_SETTINGS_V2.SUBSCRIBE_MODAL.PER_SEAT') }}
          </span>
          <span class="text-n-slate-8">•</span>
          <span class="font-semibold text-n-slate-12">
            {{ formatPrice(totalPrice) }}
            {{ t('BILLING_SETTINGS_V2.SUBSCRIBE_MODAL.TOTAL') }}
          </span>
        </div>
      </div>

      <!-- Summary -->
      <div class="p-4 rounded-lg bg-n-blue-2 dark:bg-n-blue-3 space-y-2">
        <div class="flex justify-between text-sm">
          <span class="text-n-slate-11">
            {{ t('BILLING_SETTINGS_V2.SUBSCRIBE_MODAL.BASE_PRICE') }}
          </span>
          <span class="font-semibold text-n-slate-12">
            {{ formatPrice(plan.base_price) }} {{ '×' }} {{ quantity }}
          </span>
        </div>
        <div class="flex justify-between text-sm">
          <span class="text-n-slate-11">
            {{ t('BILLING_SETTINGS_V2.SUBSCRIBE_MODAL.INCLUDED_CREDITS') }}
          </span>
          <span class="font-semibold text-n-amber-11">
            {{ formatNumber(totalCredits) }}
            {{ t('BILLING_SETTINGS_V2.SUBSCRIBE_MODAL.CREDITS') }}
          </span>
        </div>
        <div
          class="flex justify-between text-sm pt-2 border-t border-n-blue-4 dark:border-n-blue-5"
        >
          <span class="font-semibold text-n-slate-12">
            {{ t('BILLING_SETTINGS_V2.SUBSCRIBE_MODAL.MONTHLY_TOTAL') }}
          </span>
          <span class="text-lg font-bold text-n-blue-11">
            {{ formatPrice(totalPrice) }}
          </span>
        </div>
      </div>
    </div>
  </Dialog>
</template>
