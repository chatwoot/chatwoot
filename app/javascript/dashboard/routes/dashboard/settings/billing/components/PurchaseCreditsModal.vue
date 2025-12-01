<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import CreditPackageCard from './CreditPackageCard.vue';

const props = defineProps({
  options: {
    type: Array,
    default: () => [],
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['purchase', 'close']);

const { t } = useI18n();

const dialogRef = ref(null);
const selectedCredits = ref(null);

// The 3rd option (5000 credits) is marked as most popular based on Figma
const popularCreditsAmount = 5000;

const selectedOption = computed(() => {
  return props.options.find(o => o.credits === selectedCredits.value);
});

const handlePackageSelect = credits => {
  selectedCredits.value = credits;
};

const handlePurchase = () => {
  if (selectedOption.value) {
    emit('purchase', selectedOption.value);
  }
};

const handleClose = () => {
  emit('close');
};

const open = () => {
  // Pre-select the most popular option
  const popularOption = props.options.find(
    o => o.credits === popularCreditsAmount
  );
  selectedCredits.value = popularOption?.credits || props.options[0]?.credits;
  dialogRef.value?.open();
};

const close = () => {
  dialogRef.value?.close();
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('BILLING_SETTINGS.PURCHASE_MODAL.TITLE')"
    :description="t('BILLING_SETTINGS.PURCHASE_MODAL.DESCRIPTION')"
    width="xl"
    :show-confirm-button="false"
    :show-cancel-button="false"
    @close="handleClose"
  >
    <div class="grid grid-cols-2 gap-4">
      <CreditPackageCard
        v-for="option in options"
        :key="option.credits"
        :credits="option.credits"
        :amount="option.amount"
        :is-popular="option.credits === popularCreditsAmount"
        :is-selected="selectedCredits === option.credits"
        @select="handlePackageSelect(option.credits)"
      />
    </div>

    <div class="p-4 mt-4 border rounded-lg bg-n-alpha-1 border-n-weak">
      <p class="text-sm text-n-slate-11">
        {{ t('BILLING_SETTINGS.PURCHASE_MODAL.NOTE') }}
      </p>
    </div>

    <template #footer>
      <div class="flex items-center justify-between w-full gap-3">
        <Button
          variant="faded"
          color="slate"
          :label="t('BILLING_SETTINGS.PURCHASE_MODAL.CANCEL')"
          class="w-full"
          @click="close"
        />
        <Button
          color="teal"
          solid
          :label="t('BILLING_SETTINGS.PURCHASE_MODAL.PURCHASE')"
          class="w-full"
          :disabled="!selectedCredits"
          :is-loading="isLoading"
          @click="handlePurchase"
        />
      </div>
    </template>
  </Dialog>
</template>
