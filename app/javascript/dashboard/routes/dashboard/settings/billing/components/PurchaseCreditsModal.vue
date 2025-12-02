<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import CreditPackageCard from './CreditPackageCard.vue';
import EnterpriseAccountAPI from 'dashboard/api/enterprise/account';

const emit = defineEmits(['close']);

const { t } = useI18n();

const TOPUP_OPTIONS = [
  { credits: 1000, amount: 20.0, currency: 'usd' },
  { credits: 2500, amount: 50.0, currency: 'usd' },
  { credits: 5000, amount: 100.0, currency: 'usd' },
  { credits: 10000, amount: 200.0, currency: 'usd' },
];

const POPULAR_CREDITS_AMOUNT = 5000;

const dialogRef = ref(null);
const selectedCredits = ref(null);
const isLoading = ref(false);

const selectedOption = computed(() => {
  return TOPUP_OPTIONS.find(o => o.credits === selectedCredits.value);
});

const handlePackageSelect = credits => {
  selectedCredits.value = credits;
};

const handlePurchase = async () => {
  if (!selectedOption.value) return;

  isLoading.value = true;
  try {
    const response = await EnterpriseAccountAPI.createTopupCheckout(
      selectedOption.value.credits
    );
    if (response.data.redirect_url) {
      window.location.href = response.data.redirect_url;
    }
  } catch (error) {
    const errorMessage =
      error.response?.data?.error || t('BILLING_SETTINGS.TOPUP.PURCHASE_ERROR');
    useAlert(errorMessage);
  } finally {
    isLoading.value = false;
  }
};

const handleClose = () => {
  emit('close');
};

const open = () => {
  // Pre-select the most popular option
  const popularOption = TOPUP_OPTIONS.find(
    o => o.credits === POPULAR_CREDITS_AMOUNT
  );
  selectedCredits.value = popularOption?.credits || TOPUP_OPTIONS[0]?.credits;
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
    :title="$t('BILLING_SETTINGS.TOPUP.MODAL_TITLE')"
    :description="$t('BILLING_SETTINGS.TOPUP.MODAL_DESCRIPTION')"
    width="xl"
    :show-confirm-button="false"
    :show-cancel-button="false"
    @close="handleClose"
  >
    <div class="grid grid-cols-2 gap-4">
      <CreditPackageCard
        v-for="option in TOPUP_OPTIONS"
        :key="option.credits"
        name="credit-package"
        :credits="option.credits"
        :amount="option.amount"
        :currency="option.currency"
        :is-popular="option.credits === POPULAR_CREDITS_AMOUNT"
        :is-selected="selectedCredits === option.credits"
        @select="handlePackageSelect(option.credits)"
      />
    </div>

    <div class="p-4 mt-4 border rounded-lg bg-n-alpha-1 border-n-weak">
      <p class="text-sm text-n-slate-11">
        {{ $t('BILLING_SETTINGS.TOPUP.NOTE') }}
      </p>
    </div>

    <template #footer>
      <div class="flex items-center justify-between w-full gap-3">
        <Button
          variant="faded"
          color="slate"
          :label="$t('BILLING_SETTINGS.TOPUP.CANCEL')"
          class="w-full"
          @click="close"
        />
        <Button
          color="blue"
          :label="$t('BILLING_SETTINGS.TOPUP.PURCHASE')"
          class="w-full"
          :disabled="!selectedCredits"
          :is-loading="isLoading"
          @click="handlePurchase"
        />
      </div>
    </template>
  </Dialog>
</template>
