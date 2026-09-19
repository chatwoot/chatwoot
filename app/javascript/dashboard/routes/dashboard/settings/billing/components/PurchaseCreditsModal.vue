<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import CreditPackageCard from './CreditPackageCard.vue';
import EnterpriseAccountAPI from 'dashboard/api/enterprise/account';
import {
  formatCurrencyAmount,
  DEFAULT_BILLING_CURRENCY,
} from 'dashboard/constants/billing';

const emit = defineEmits(['success']);

const { t } = useI18n();

const POPULAR_CREDITS_AMOUNT = 6000;
const STEP_SELECT = 'select';
const STEP_CONFIRM = 'confirm';

const dialogRef = ref(null);
const selectedCredits = ref(null);
const isLoading = ref(false);
const currentStep = ref(STEP_SELECT);

// Topup packages come from the backend for the account's billing currency.
const topupOptions = ref([]);
const optionsCurrency = ref(DEFAULT_BILLING_CURRENCY);
const isFetchingOptions = ref(false);
const fetchError = ref(false);

const selectedOption = computed(() => {
  return topupOptions.value.find(o => o.credits === selectedCredits.value);
});

const formattedAmount = computed(() => {
  if (!selectedOption.value) return '';
  const { amount, currency } = selectedOption.value;
  return formatCurrencyAmount(amount, currency || optionsCurrency.value);
});

const formattedCredits = computed(() => {
  if (!selectedOption.value) return '';
  return selectedOption.value.credits.toLocaleString();
});

const dialogTitle = computed(() => {
  return currentStep.value === STEP_SELECT
    ? t('BILLING_SETTINGS.TOPUP.MODAL_TITLE')
    : t('BILLING_SETTINGS.TOPUP.CONFIRM.TITLE');
});

const dialogDescription = computed(() => {
  return currentStep.value === STEP_SELECT
    ? t('BILLING_SETTINGS.TOPUP.MODAL_DESCRIPTION')
    : '';
});

const dialogWidth = computed(() => {
  return currentStep.value === STEP_SELECT ? 'xl' : 'md';
});

const handlePackageSelect = credits => {
  selectedCredits.value = credits;
};

const selectDefaultOption = () => {
  const popularOption = topupOptions.value.find(
    o => o.credits === POPULAR_CREDITS_AMOUNT
  );
  selectedCredits.value =
    popularOption?.credits || topupOptions.value[0]?.credits || null;
};

const fetchOptions = async () => {
  isFetchingOptions.value = true;
  fetchError.value = false;
  try {
    const { data } = await EnterpriseAccountAPI.getTopupOptions();
    topupOptions.value = data.options ?? [];
    optionsCurrency.value = (
      data.currency || DEFAULT_BILLING_CURRENCY
    ).toLowerCase();
    selectDefaultOption();
  } catch {
    fetchError.value = true;
    topupOptions.value = [];
  } finally {
    isFetchingOptions.value = false;
  }
};

const open = () => {
  currentStep.value = STEP_SELECT;
  isLoading.value = false;
  selectedCredits.value = null;
  dialogRef.value?.open();
  fetchOptions();
};

const close = () => {
  dialogRef.value?.close();
};

const goToConfirmStep = () => {
  if (!selectedOption.value) return;
  currentStep.value = STEP_CONFIRM;
};

const goBackToSelectStep = () => {
  currentStep.value = STEP_SELECT;
};

const handlePurchase = async () => {
  if (!selectedOption.value) return;

  isLoading.value = true;
  try {
    const response = await EnterpriseAccountAPI.createTopupCheckout(
      selectedOption.value.credits
    );

    close();
    emit('success', response.data);
    useAlert(
      t('BILLING_SETTINGS.TOPUP.PURCHASE_SUCCESS', {
        credits: response.data.credits,
      })
    );
  } catch (error) {
    const errorMessage =
      error.response?.data?.error || t('BILLING_SETTINGS.TOPUP.PURCHASE_ERROR');
    useAlert(errorMessage);
  } finally {
    isLoading.value = false;
  }
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="dialogTitle"
    :description="dialogDescription"
    :width="dialogWidth"
    :show-confirm-button="false"
    :show-cancel-button="false"
  >
    <!-- Step 1: Select Credits Package -->
    <template v-if="currentStep === STEP_SELECT">
      <div
        v-if="isFetchingOptions"
        class="flex items-center justify-center gap-2 py-10"
      >
        <Spinner />
        <span class="text-sm text-n-slate-11">{{
          $t('BILLING_SETTINGS.TOPUP.LOADING')
        }}</span>
      </div>

      <div
        v-else-if="fetchError"
        class="flex flex-col items-center justify-center gap-3 py-10"
      >
        <p class="text-sm text-n-slate-11">
          {{ $t('BILLING_SETTINGS.TOPUP.FETCH_ERROR') }}
        </p>
        <Button
          variant="faded"
          color="slate"
          :label="$t('BILLING_SETTINGS.TOPUP.RETRY')"
          @click="fetchOptions"
        />
      </div>

      <template v-else>
        <div class="grid grid-cols-2 gap-4">
          <CreditPackageCard
            v-for="option in topupOptions"
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

        <div class="p-4 mt-6 rounded-lg bg-n-solid-2 border border-n-weak">
          <p class="text-sm text-n-slate-11">
            <span class="font-semibold text-n-slate-12">{{
              $t('BILLING_SETTINGS.TOPUP.NOTE_TITLE')
            }}</span>
            {{ $t('BILLING_SETTINGS.TOPUP.NOTE_DESCRIPTION') }}
          </p>
        </div>
      </template>
    </template>

    <!-- Step 2: Confirm Purchase -->
    <template v-else>
      <div class="flex flex-col gap-4">
        <p class="text-sm text-n-slate-11">
          {{
            $t('BILLING_SETTINGS.TOPUP.CONFIRM.DESCRIPTION', {
              credits: formattedCredits,
              amount: formattedAmount,
            })
          }}
        </p>

        <div class="p-2.5 rounded-lg bg-n-amber-2 border border-n-amber-6">
          <p class="text-sm text-n-amber-11">
            {{ $t('BILLING_SETTINGS.TOPUP.CONFIRM.INSTANT_DEDUCTION_NOTE') }}
          </p>
        </div>
      </div>
    </template>

    <template #footer>
      <!-- Step 1 Footer -->
      <div
        v-if="currentStep === STEP_SELECT"
        class="flex items-center justify-between w-full gap-3"
      >
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
          :disabled="!selectedCredits || isFetchingOptions || fetchError"
          @click="goToConfirmStep"
        />
      </div>

      <!-- Step 2 Footer -->
      <div v-else class="flex items-center justify-between w-full gap-3">
        <Button
          variant="faded"
          color="slate"
          :label="$t('BILLING_SETTINGS.TOPUP.CONFIRM.GO_BACK')"
          class="w-full"
          :disabled="isLoading"
          @click="goBackToSelectStep"
        />
        <Button
          color="blue"
          :label="$t('BILLING_SETTINGS.TOPUP.CONFIRM.CONFIRM_PURCHASE')"
          class="w-full"
          :is-loading="isLoading"
          @click="handlePurchase"
        />
      </div>
    </template>
  </Dialog>
</template>
